class Receipt < ApplicationRecord

  include Filterable

  belongs_to :client
  belongs_to :currency
  belongs_to :payment_form
  belongs_to :user
  belongs_to :tenant
  belongs_to :invoice, optional: true

  before_validation :populate_exchange_rate
  validates :reference_number, uniqueness: true
  validates :source_reference, uniqueness: { scope: :device_id, message: "Source reference is already taken!" }, presence: true
  validates :client_id, :transaction_date, :currency_id, :payment_form_id, :reference_number, :amount, :rate, :description, presence: true
  validate :amount_cannot_be_zero
  validate :rate_cannot_be_zero
  validate :invoice_required_when_setting_enabled
  validate :transaction_date_cannot_be_in_future
  validate :reason_required_for_non_payment

  enum :receipt_type, {
    payment: "Payment",
    setoff: "Setoff",
    write_off: "Write Off"
  }


  # validates :transaction_source, inclusion: { in: ['BaseApplication','MobilePhone']}

  has_one_attached :qr_code, dependent: :destroy

  before_commit :generate_qrcode, on: :create
  before_commit :update_statement, on: :update
  before_save :set_actual_paid, if: :payment_details_changing?
  after_save :refresh_invoice_balances, if: :payment_details_changed?
  after_commit :settle_client_from_statement, on: :create, if: -> { invoice_id.nil? }

  scope :active, -> {where(deleted: false)}
  scope :between_dates, ->(start_date, end_date) {active.includes(:currency, :payment_form).where(transaction_date: start_date..end_date)}

  PAYMENT_DETAILS = %w[amount rate currency_id invoice_id deleted receipt_type].freeze

  def self.generate_receipt_number(tenant)
    rec_format = tenant.system_settings
                       .joins(:config_key)
                       .find_by(config_keys: { name: "Receipt No." })
                       &.config_value

    return unless rec_format.present?

    last = tenant.receipts.where(receipt_type: 'Payment').order(id: :desc).first

    rec_no = last.present? ? last.reference_number.next : rec_format

    rec_no
  end

  def client_name
    self.client.name unless self.client.nil?
  end

  def username
    self.user.username
  end

  def receipt_number
    self.reference_number
  end

  def receipt_date
    self.transaction_date.strftime("%Y%m%d")
  end

  def currency_used
    currency.name
  end

  def payment_method
    payment_form.name
  end

  def amount_paid
    return amount unless invoice.present?
    return amount if currency_id == invoice.currency_id || rate.to_f.zero?

    if invoice.currency.name == "USD"
      amount / rate.to_f
    else
      amount * rate.to_f
    end
  end

  def rated_amount(target_currency)
    amount = self.amount
    if target_currency.id != self.currency_id
      if target_currency.id == base_currency.id
        amount = amount/rate.to_f
      else
        amount = amount*rate.to_f
      end
    end
    amount  
  end

  def self.filter(from,to,currency_id,user_id)
    receipts = Receipt.active.order(currency_id: :asc, transaction_date: :asc)
    receipts = receipts.where(transaction_date: from.to_date..to.to_date) if from.present? && to.present?
    receipts = receipts.where("currency_id = ?", currency_id) if currency_id.present?
    receipts = receipts.where("user_id = ?", user_id) if user_id.present?
    receipts
  end

  def self.group_by_user(from,to,currency_id)
    receipts = Receipt.select("user_id, SUM(amount) as total").group(:user_id).active
    receipts = receipts.where(transaction_date: from.to_date..to.to_date) if from.present? && to.present?
    receipts = receipts.where("currency_id = ?", currency_id) if currency_id.present?
    receipts
  end

  def self.import_receipts(file,tenant,default_currency,exchange_rate_update_frequency)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      user = User.find_by(username: "#{row["Username"]}")
      client = Client.find_by(name: "#{row["Client"]}")
      shift = Shift.where(active: true).last
      @currency = Currency.find_by(name: "#{row["Currency"]}")
      @payment_form = PaymentForm.find_by(name: "#{row["Type"]}")
      puts("**** #{row["Invoice Date"]}")
      unless user.nil? || client.nil?
        unless Receipt.exists?(source_reference: "#{row["Source Reference"]}", user_id: user.id)
          puts("create #{row["Source Reference"]}, amount paid #{row["Amount Paid"]}")
          current_device = Device.find_by(user_id: user.id)
          receipt = Receipt.new
          receipt.client_id = client.id
          receipt.currency_id = @currency.id unless @currency.nil?
          receipt.payment_form_id = @payment_form.id unless @payment_form.nil?
          receipt.amount = row["Amount Paid"].to_f
          receipt.user_id = user.id
          receipt.user_fullname = user.fullname
          receipt.transaction_date = row["Receipt Date"].to_s.to_date
          # auto generate receipt number
          unless tenant.system_settings.empty?
            rec_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Receipt No.').id).config_value
            receipts = Receipt.order('reference_number Asc').where(tenant_id: current_device.tenant_id)
            if receipts.empty?
              receipt.reference_number = rec_format
            else
              receipt.reference_number = receipts[-1].reference_number.next
            end
          end
          transaction_date = row["Receipt Date"].to_s.to_date
          if @currency.id == default_currency.id
            receipt.rate = 1
            receipt.actual_paid = row["Amount Paid"].to_f
          else
            rate = ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency)
            receipt.rate = rate.to_f
            receipt.actual_paid = row["Amount Paid"].to_f*rate.to_f
          end
          receipt.tenant_id = client.tenant_id
          client_invoice = Invoice.where(client_id: client.id).last
          unless client_invoice.nil?
            receipt.invoice_reference = client_invoice.source_reference
            receipt.invoice_id = client_invoice.id
            receipt.business_nature = client_invoice.license.license_category.name
          else
            receipt.invoice_reference = nil
            receipt.business_nature = client.industry.name                 
          end
          receipt.description = client.industry.name
          receipt.source_reference = "#{row["Source Reference"]}"
          receipt.sync_reference = "#{row["Source Reference"]}"
          receipt.transaction_source = current_device.model
          receipt.transaction_source_id = current_device.terminal_id
          receipt.shift_id = shift.id
          receipt.device_id = current_device.id 
          receipt.gps_longitude = nil
          receipt.gps_latitude = nil
          receipt.is_synced = true
          if receipt.save
            # find the invoice with the reference and update invoice_id
            invoiced = Invoice.where(client_id: client.id).last
            unless invoiced.nil?
              invoiced.update_payment_status
            end
            puts("Receipt saved successfully.")
          else
            errors = []
            receipt.errors.each do |e|
              errors << e.full_message
            end
            puts("#{errors}")
          end
        else
          puts("#{row["Source Reference"]} already exists")
        end
      end
    end
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Roo::Csv.new(file.path, nil, :ignore)
    when ".xls" then Roo::Excel.new(file.path, packed: false, file_warning: :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, packed: false, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  private

  def invoice_required_when_setting_enabled
    return unless tenant&.attach_invoice_to_receipt?

    if invoice_id.blank? && invoice_reference.blank?
      errors.add(:invoice, "must be attached to this receipt")
    end
  end

  # What the receipt's QR code says. The printed receipt and the receipt page both draw the code
  # from this text every time, so it never depends on a stored image file.
  def verification_text(company_name = tenant&.company_name)
    amount_text = ActiveSupport::NumberHelper.number_to_delimited(format("%.2f", amount.to_d))
    "#{company_name} receipt #{reference_number}: #{currency&.name} #{amount_text} from #{client&.name} " \
      "on #{transaction_date&.strftime('%d %b %Y')}#{' (VOID)' if deleted?}."
  end

  def verification_qr_svg(company_name = tenant&.company_name)
    RQRCode::QRCode.new(verification_text(company_name), level: :m)
                   .as_svg(module_size: 4, use_path: true, viewbox: true, standalone: true, offset: 0, color: "1f1a17")
  end
  public :verification_text, :verification_qr_svg

  def generate_qrcode

    qrcode = RQRCode::QRCode.new("#{client.name} #{self.reference_number} | Date: #{transaction_date.strftime("%d %b %Y")} | Amount #{self.currency.symbol} #{sprintf("%0.02f", self.amount)} for #{self.description}")

    # NOTE: showing with default options specified explicitly
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )

    self.qr_code.attach(
      io: StringIO.new(png.to_s),
      filename: "qr_code.png",
      content_type: "image/png"
      )
  end

  def payment_details_changing?
    new_record? || (changed & PAYMENT_DETAILS).any?
  end

  def payment_details_changed?
    (saved_changes.keys & (PAYMENT_DETAILS + ["actual_paid"])).any?
  end

  def set_actual_paid
    self.actual_paid = amount_paid
  end

  def refresh_invoice_balances
    ids = [invoice_id, invoice_id_before_last_save].compact.uniq
    Invoice.where(id: ids).find_each(&:update_balance)
  end

  # A receipt with no invoice can still settle a client's account, so licences
  # should not have to wait for someone to press Refresh.
  def settle_client_from_statement
    client.settle_licenses_from_statement
  rescue StandardError => e
    Rails.logger.error("Could not settle licences for client #{client_id}: #{e.message}")
    SystemEvent.record(kind: "payment_sync", tenant_id: tenant_id, record: self,
                       title: "Receipt #{reference_number} could not settle #{client&.name}'s licences",
                       details: "#{e.class}: #{e.message}")
  end

  def update_statement
    transaction = Transaction.find_by(source: "Receipts", source_id: self.id)
    unless transaction.nil?
      transaction.update(
        transaction_date: self.transaction_date,
        description: self.description, 
        deleted: self.deleted
        )
    end
  end

  def transaction_date_cannot_be_in_future
    return if transaction_date.blank?

    Rails.logger.info "=== RECEIPT DATE DEBUG ==="
    Rails.logger.info "transaction_date: #{transaction_date.inspect}"
    Rails.logger.info "transaction_date class: #{transaction_date.class}"
    Rails.logger.info "Date.current: #{Date.current.inspect}"
    Rails.logger.info "Time.zone.today: #{Time.zone.today.inspect}"
    Rails.logger.info "comparison: #{transaction_date > Date.current}"
    Rails.logger.info "=========================="

    errors.add(:transaction_date, "cannot be in the future") if transaction_date > Date.current
  end

  def amount_cannot_be_zero
    errors.add(:amount, " cannot be zero.") if amount.nil? || amount <= 0
  end

  def rate_cannot_be_zero
    errors.add(:rate, " cannot be zero. Enter valid rate.") if rate.nil? || rate <= 0
  end

  # def populate_exchange_rate
  #   # tenant = self.tenant
  #   self.sync_reference = source_reference
  #   rate = 1  
  #   exchange_rate = ExchangeRate.active_exchange_rate(tenant,transaction_date,exchange_rate_update_frequency)
  #   puts("apo ************************ #{exchange_rate}")
  #   unless exchange_rate.nil?
  #     self.rate = exchange_rate
  #     self.converted_rate = 1/exchange_rate
  #   else
  #     self.rate = rate
  #     self.converted_rate = 1
  #   end

  # end

  def populate_exchange_rate
    self.sync_reference = source_reference

    # USD is the base currency: no exchange rate needed, unless it pays a
    # non-USD invoice (amount_paid converts using the rate in that case).
    if currency_id.present? && base_currency && currency_id == base_currency.id &&
       (invoice.nil? || invoice.currency_id == currency_id)
      self.rate = 1.to_d
      self.converted_rate = 1.to_d
      return
    end

    exchange_rate = ExchangeRate.active_exchange_rate(
      tenant,
      transaction_date.to_date,
      exchange_rate_update_frequency
    )

    if exchange_rate.present?
      self.rate = exchange_rate.to_d
      self.converted_rate = 1.to_d / exchange_rate.to_d
    else
      errors.add(
        :rate,
        "No valid exchange rate exists for #{transaction_date.to_date}"
      )
    end
  end

  def reason_required_for_non_payment
    return if payment?
    return if reason.present?

    errors.add(:reason, "is required for #{receipt_type}")
  end

end

class Invoice < ApplicationRecord
  belongs_to :client
  belongs_to :user
  belongs_to :currency
  belongs_to :invoice_category, optional: true
  has_and_belongs_to_many :banks
  has_and_belongs_to_many :branches
  has_many :invoice_items
  has_many :receipts
  has_one :credit_note
  has_one :license

  attr_accessor :unit_price, :quantity

  enum :status, {
    fully_paid: "Fully Paid",
    not_paid: "Not Paid",
    partly_paid: "Partly Paid",
    overpaid: "Overpaid",
    void: "Void",
    deleted: "Deleted"
  }

  # The status enum's "deleted" value defines deleted? as "status is Deleted", which hides
  # the deleted column's own query method. Every caller means the column, so restore it.
  def deleted?
    self[:deleted] == true
  end

  after_update :update_associated_license
  # Keep the client statement in step when an invoice is deleted, voided or restored.
  after_commit :sync_statement_line, on: :update, if: :saved_change_to_deleted?
  # A licence invoice that becomes fully paid marks its licence paid, which queues it for approval.
  after_save :mark_license_paid, if: -> { saved_change_to_paid?(to: true) }
  before_validation :populate_invoice_items
  validate :invoice_items_cannot_be_empty
  validate :discount_within_invoice, if: :will_save_change_to_discount?
  # validates :bank_id, presence: true
  validates :invoice_date, uniqueness: { scope: [:client_id, :invoice_total, :deleted], message: "Possible invoice duplicate per client." }

  accepts_nested_attributes_for :invoice_items, allow_destroy: true, reject_if: proc { |attributes| attributes['description'].blank? }
  accepts_nested_attributes_for :license#, allow_destroy: true, reject_if: proc { |attributes| attributes['license_category_id'].blank? }

  scope :proforma, -> {where(is_proforma: true, deleted: false)}
  scope :sales, -> {where(is_proforma: false, deleted: false)}
  scope :all_proformas, -> {where(is_proforma: true)}
  scope :all_sales, -> {where(is_proforma: false)}
  scope :active, -> {where(deleted: false)}
  scope :unpaid, -> {where(deleted: false, paid: false)}
  scope :inactive, -> {where(deleted: true)}
  # One rule for "overdue" everywhere (sidebar badge, Invoices tab): a real invoice, not deleted,
  # with money still owing, past its due date (or invoice date + validity days when it has none).
  scope :overdue_after, ->(validity_days, today = Date.current) {
    sales.where("invoices.invoice_total > invoices.amount_paid")
         .where("COALESCE(invoices.due_date, invoices.invoice_date + CAST(? AS integer)) < ?", validity_days.to_i, today)
  }

  scope :between_dates, ->(start_date, end_date) {includes(:currency).where(invoice_date: start_date..end_date)}

  def is_license
    invoice_category&.name == "License"
  end

  def client_name
    client.name
  end

  def document
    return 'TAX INVOICE' if self.is_proforma == false
    return 'PROFORMA INVOICE' if self.is_proforma == true
  end

  # def bank
  #   unless self.bank_id.nil?
  #     Bank.find(self.bank_id)
  #   end
  # end

  def statement_description
    d = self.description
    if self.description.nil?
      unless self.invoice_items.empty?
        d = self.invoice_items[0].description
      else
        d = "Invoice #{self.invoice_number}"
      end
    end
    d
  end

  def invoice_details
    "#{self.invoice_number} (Bal #{self.currency.symbol} #{sprintf("%0.02f", self.invoice_balance)})"
  end

  def sub_total
    license_value(:amount) { invoice_items.active.sum(&:net_total) }
  end

  # VAT follows the discount, so tax is charged on the reduced price.
  def vat
    before_discount = license_value(:vat) { invoice_items.active.sum(:line_vat) }
    return before_discount unless discount_amount.positive?

    before_discount * (1 - discount_amount / sub_total.to_d)
  end

  def discount_amount
    [discount.to_d, sub_total.to_d].min
  end

  def total
    sub_total - discount_amount + vat
  end

  def rated_invoice_total(target_currency)
    tt = total
    if target_currency.id != self.currency_id
      if target_currency.id == base_currency.id
        tt = tt/rate.to_f unless rate.to_f == 0
      else
        tt= tt*rate.to_f unless rate.to_f == 0
      end
    end
    tt
  end

  def total_paid
    received_through("payment")
  end

  def total_setoff
    received_through("setoff")
  end

  def total_writeoff
    received_through("write_off")
  end

  # Worked out from each receipt's amount, rate and currency. Older rows have a
  # wrong stored actual_paid, so that column cannot be trusted.
  def received_through(receipt_type)
    receipts.active.where(receipt_type: receipt_type).to_a.sum { |receipt| receipt.amount_paid.to_d.round(2) }
  end

  def total_amount_paid
    total_paid + total_setoff + total_writeoff
  end

  def update_balance
    self.invoice_total = total
    self.amount_paid = total_amount_paid

    update_invoice_status

    self.last_payment_update = Time.current

    # Only derived figures change here, so an old validation issue on the
    # invoice must not block recording a payment.
    save!(validate: false)
  end

  # Corrects the stored figures only when they are wrong. Returns true if saved.
  def sync_balance
    return false if would_lose_paid_status? && client_has_unallocated_receipts?

    prepare_balance
    return save_prepared_balance if balance_needs_saving?

    restore_attributes
    false
  end

  def prepare_balance
    self.invoice_total = total
    self.amount_paid = total_amount_paid
    update_invoice_status
  end

  def balance_needs_saving?
    (changed - ["last_status_update"]).any?
  end

  def save_prepared_balance
    save!(validate: false)
    true
  rescue ActiveRecord::RecordNotUnique => e
    Rails.logger.warn("Could not correct invoice #{id}: #{e.message}")
    SystemEvent.record(kind: "payment_sync", tenant_id: tenant_id, record: self,
                       title: "Invoice #{invoice_number}'s balance could not be corrected", details: e.message)
    restore_attributes
    false
  end

  # Receipts with no invoice can settle a client through the statement alone,
  # so those invoices cannot be judged from their own receipts.
  def would_lose_paid_status?
    paid? && total.to_d.round(2) - total_amount_paid.to_d.round(2) > 0
  end

  def client_has_unallocated_receipts?
    Receipt.active.where(client_id: client_id, invoice_id: nil).exists?
  end

  def sync_statement_line
    Transaction.where(source: "Invoices", source_id: id, journal: [false, nil])
               .update_all(deleted: deleted?, updated_at: Time.current)
  end

  def update_invoice_status
    balance = invoice_balance.to_d.round(2)

    if deleted?
      self.status = :deleted unless void?
      self.paid = false
    elsif balance < 0
      self.status = :overpaid
      self.paid = true
    elsif balance <= 0
      self.status = :fully_paid
      self.paid = true
    elsif amount_paid.to_d > 0
      self.status = :partly_paid
      self.paid = false
    else
      self.status = :not_paid
      self.paid = false
    end

    self.last_status_update = Time.current
  end

  def update_invoice_and_license(attributes)
    transaction do
      update!(attributes)

      update_balance

      update_associated_license
    end
  end

  def invoice_balance
    total.to_d - total_amount_paid.to_d
  end

  # Statement methods by currency
  def invoice_sub_total(currency)
    t = 0
    if is_license
      t = license.amount unless license.nil?
    else
      t = invoice_items.active.sum(&:net_total)
    end
    t
  end

  def update_associated_license
    return unless license.present?

    # The invoice is the source of truth. Skip validation so a zero-total invoice
    # cannot silently roll back its own void or update.
    # A discounted invoice keeps the licence's full price, or the discount would apply twice.
    license.amount = invoice_total unless discount_amount.positive?
    license.assign_attributes(status: status, paid: self.paid)
    license.save!(validate: false)
  end

  def invoice_vat(currency)
    t = 0
    puts("reporting currency #{currency.name}")
    # get the invoice currency
    if currency.id == base_currency.id and self.currency_id == currency.id
      puts("reporting in USD and our invoice is in USD") 
      if is_license
        t = license.vat unless license.nil?
      else
        t = invoice_items.active.sum(:line_vat)
      end
    elsif currency.id == base_currency.id and currency.id != self.currency_id
      puts("reporting in USD and our invoice is in ZWG with #{license.vat}/#{self.rate}") 
      if is_license
        t = license.vat/self.rate unless license.nil? || license.vat == 0
      else
        t = (invoice_items.active.sum(:line_vat))/self.rate
      end
    elsif currency.id != base_currency.id and currency.id == self.currency_id
      puts("reporting in ZWG and our invoice is in ZWG")
      if is_license
        t = license.vat unless license.nil?
      else
        t = invoice_items.active.sum(:line_vat)
      end
    elsif currency.id != base_currency.id and currency.id != self.currency_id 
      puts("reporting in ZWG and our invoice is in USD")
      if is_license
        t = license.vat*self.rate unless license.nil?
      else
        t = invoice_items.active.sum(:line_vat).to_f*self.rate
      end
    end
    t
  end

  def total_invoice(currency)
    sub_total + vat
  end

  def balance
    invoice_total - amount_paid
  end

  def user_fullname
    user.user_fullname
  end

  def username
    user.username
  end

  def invoice_currency
    currency.name
  end

  def invoiced_on
    self.invoice_date.strftime("%Y%m%d")
  end

  def license_period
    self.license.license_category.name
  end

  def renewal_date
    self.license.renewal_date.strftime("%Y%m%d")
  end

  def expiry_date
    self.license.expiry_date.strftime("%Y%m%d")
  end

  def sync_reference
    source_reference.presence || invoice_number
  end

  # Older invoices have no due date, so fall back to the invoice's validity period.
  def effective_due_date(validity_days)
    due_date || (invoice_date && invoice_date + validity_days.to_i.days)
  end

  def days_overdue(validity_days)
    due = effective_due_date(validity_days)
    due ? [(Date.current - due).to_i, 0].max : 0
  end

  # def age
  #   a = 0
  #   unless self.paid
  #     a = (Date.today - self.due_date).to_i
  #   end
  #   a
  # end

  # def update_debtors_age
  #   # update the last debtors update, payment and age
  #   if self.last_payment_update.nil?
  #     receipts = Receipt.active.order(transaction_date: :asc).where(invoice_id: self.id)
  #     unless receipts.empty?
  #       self.update(last_payment_update: receipts[-1].transaction_date)    
  #     end 
  #   end
       
  #   unless self.last_debtors_update.nil?
  #     unless self.last_payment_update.nil?
  #       if self.last_debtors_update.to_date < Date.today || self.last_debtors_update < self.last_payment_update
  #         puts("do the comparison and update")
  #         self.update(debtors_age: age, last_debtors_update: Time.now + 2.hours) 
  #       end
  #     else
  #       if self.last_debtors_update.to_date < Date.today
  #         self.update(debtors_age: age, last_debtors_update: Time.now + 2.hours) 
  #       end
  #     end
  #   else
  #     puts("initialize debtors update")
  #     self.update(debtors_age: age, last_debtors_update: Time.now + 2.hours)
  #   end
  # end

  def age(report_date = Date.current)
    return 0 if paid || due_date.blank?

    (report_date.to_date - due_date.to_date).to_i
  end

  def update_debtors_age(report_date = Date.current)
    report_date = report_date.to_date

    latest_payment_date = Receipt.active
                                 .where(invoice_id: id)
                                 .maximum(:transaction_date)

    payment_changed = last_payment_update != latest_payment_date

    ageing_outdated = last_debtors_update.nil? ||
                      last_debtors_update.to_date < report_date

    return false unless ageing_outdated || payment_changed

    calculated_age = age(report_date)

    update_columns(
      debtors_age: calculated_age,
      last_payment_update: latest_payment_date,
      last_debtors_update: Time.current
    )

    Rails.logger.info(
      "Invoice #{id}: Ageing updated to #{calculated_age} days"
    )

    true
  end

  def update_payment_status
    return if deleted?

    if amount_paid.to_f >= invoice_total.to_f
      update!(
        status: :fully_paid,
        paid: true
      )
    elsif amount_paid.to_f > 0
      update!(
        status: :partly_paid,
        paid: false
      )
    else
      update!(
        status: :not_paid,
        paid: false
      )
    end
  end

  # def validate_license
  #   l = InvoiceCategory.find_by(name: 'License')
  #    if self.invoice_category_id == l.id
  #       self.license = true
  #    end
  # end

  def self.filter(start_date,end_date,currency_id,user_id,tenant)
    invoices = Invoice.active.order(currency_id: :asc, invoice_date: :asc).where(tenant_id: tenant.id)
    invoices = invoices.where(tenant_id: tenant.id, invoice_date: start_date.to_date..end_date.to_date) if start_date.present? && end_date.present?
    invoices = invoices.where("tenant_id = #{tenant.id} AND currency_id = ?", currency_id) if currency_id.present?
    invoices = invoices.where("tenant_id = #{tenant.id} AND user_id = ?", user_id) if user_id.present?
    invoices
  end

  def self.group_by_user(start_date,end_date,currency_id)
    invoices = Invoice.select("user_id, SUM(invoice_total) as total").group(:user_id).active
    invoices = invoices.where(invoice_date: start_date.to_date..end_date.to_date) if start_date.present? && end_date.present?
    invoices = invoices.where("currency_id = ?", currency_id) if currency_id.present?
    invoices
  end

  def self.import_invoices(file,tenant)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      user = User.find_by(username: "#{row["Username"]}")
      client = Client.find_by(name: "#{row["Client"]}")
      shift = Shift.where(active: true).last
      @currency = Currency.find_by(name: "USD")
      puts("**** #{row["Invoice Date"]}")
      unless user.nil? || client.nil?
        unless Invoice.exists?(source_reference: "#{row["Source Reference"]}", user_id: user.id)
          puts("create #{row["Source Reference"]}")

          current_device = Device.find_by(user_id: user.id)
          invoice = self.new
          invoice.invoice_category_id = 2
          invoice.client_id = client.id
          invoice.currency_id = @currency.id unless @currency.nil?
          invoice.user_id = user.id
          invoice.invoice_date = row["Invoice Date"].to_s.to_date
          # auto generate invoice number
          unless tenant.system_settings.empty?
            inv_format = tenant.system_settings.find_by(config_key_id: ConfigKey.find_by(name: 'Invoice No.').id).config_value
            invoices = Invoice.order('invoice_number Asc').where(is_proforma: false, tenant_id: tenant.id)
            if invoices.empty?
              invoice.invoice_number = inv_format
            else
              invoice.invoice_number = invoices[-1].invoice_number.next
            end
          end
          invoice.tenant_id = tenant.id
          invoice.shift_id = shift.id
          invoice.device_id = current_device.id
          invoice.gps_longitude = ""
          invoice.gps_latitude = ""
          invoice.source_reference = "#{row["Source Reference"]}"
          invoice.is_synced = true
          invoice.invoice_total = row["Invoice Amount"].to_f
          # invoice.bank_id = tenant.banks[0].id
          invoice.product_pricing = 'none'
          @vat_type = VatType.find_by(name: 'Non VAT')
          category = LicenseCategory.first
          option = LicenseOption.find_by(name: 'Monthly')
          unless row["Option"].nil?
            option = LicenseOption.find_by(name: "#{row["Option"]}")
          end
          unless row["License Category"].nil?
            category = LicenseCategory.find_by(name: "#{row["License Category"]}")
          end
          
          1.times {invoice.build_license(license_category_id: category.id, license_option_id: option.id, renewal_date: row["Renewal Date"].to_s.to_date, quantity: 1, amount: row["Invoice Amount"].to_f, special_days: 0)}
          if invoice.save
            puts("Invoice saved successfully.")
          else
            errors = []
            invoice.errors.each do |e|
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

  def license_value(attribute)
    if license?
      license&.public_send(attribute) || 0
    else
      yield
    end
  end

  def discount_within_invoice
    errors.add(:discount, "cannot be negative") if discount.to_d.negative?
    errors.add(:discount, "cannot be more than the invoice subtotal") if discount.to_d > sub_total.to_d
  end

  def populate_invoice_items
    # if self.invoice_category_id == 2 and invoice_items.empty?
    #   self.invoice_items.build(description: "#{license.}", quantity: self.quantity, unit_price: self.unit_price, vat_type_id: self.vat_type_id)
    # end
  end

  def invoice_items_cannot_be_empty
    # if self.invoice_items.empty? || self.license.nil?
    #   errors.add(:invoice_id, "Please add atleast one invoice item")
    # end
  end


  def mark_license_paid
    lic = License.find_by(invoice_id: id)
    return if lic.nil? || lic.paid?

    # Only the paid flag changes, so an old validation problem on the licence must not stop it.
    lic.paid = true
    lic.status = "Fully Paid"
    lic.save!(validate: false)
  rescue StandardError => e
    Rails.logger.error("Could not mark licence paid for invoice #{id}: #{e.message}")
    SystemEvent.record(kind: "payment_sync", tenant_id: tenant_id, record: self,
                       title: "Invoice #{invoice_number} is paid but its licence could not be marked paid",
                       details: "#{e.class}: #{e.message}. The licence will not reach the approval queue until this is fixed.")
  end

end

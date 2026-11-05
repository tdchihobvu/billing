class License < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :invoice
  belongs_to :client
  belongs_to :license_category
  belongs_to :license_option

  has_one_attached :qr_code, dependent: :destroy

  before_save :license_expiry, :populate_client

  before_commit :generate_qrcode, on: :create

  before_validation :populate_client

  validates :license_category_id, :license_option_id, presence: true
  validate :amount_cannot_be_zero

  scope :active, -> {where("active = true AND expiry_date >= '#{Date.today}'")}
  scope :paid, -> {where(active: true, paid: true)}
  scope :unprinted, -> {where(active: true, paid: true, printed: false)}

  def paid_status
    # get the client
    as_at = Date.today
    var = invoice.client.account_balance_as_at(as_at,target_currency)
    case 
    when var >= 0 
      self.update_attribute(:status, 'Fully Paid')
    end
  end

  def license_for
    license = ""
    unless license_category_id.nil?
      license = license_category.name
    end
    license
  end

  def unit_price
      self.amount.to_f/self.quantity.to_i
  end

  def period
    "#{renewal_date.strftime("%b %Y")} to #{expiry_date.strftime("%b %Y")}"
  end

  def long_period
    "#{renewal_date.strftime("%d %b %Y")} to #{expiry_date.strftime("%d %b %Y")}"
  end

  def client
    nil
    unless self.client_id.nil?
      Client.find(self.client_id)
    end
  end

  def vat
    # get vat type
    vat_type = VatType.find_by(name: 'VAT 15%')
    # calculate net price
    vat = 0
    unless vat_type.nil?
      rate = vat_type.rate
      if invoice.product_pricing == "inclusive"
        net_price = self.amount.to_f/(1 + (rate.to_f/100))
        vat = self.unit_price.to_f - net_price
      elsif  invoice.product_pricing == "exclusive"
        net_price = self.unit_price
        vat = net_price.to_f * (rate.to_f/100)
      else
        net_price = self.unit_price
        vat = 0
      end
    end
    vat   
  end

  def sub_total
    amount - vat
  end

  def line_vat
    vat.to_f * quantity
  end

  def validate_paid
    target_currency = client.currency
    invoice = Invoice.find(self.invoice_id)
    as_at = Date.today
    # get the client statement balance
    unless client.receipts.empty?
      puts("****************** #{client.name} #{client.id}")
      if client.account_balance_as_at(as_at,target_currency) <= 0.5 and client.credits_total_as_at(as_at,target_currency) > 0
        puts("balance is #{client.account_balance_as_at(as_at,target_currency)} and credits are #{client.credits_total_as_at(as_at,target_currency)}")
        self.update_attribute(:paid, true)
        self.update_attribute(:status, 'Fully Paid')
        unless invoice.nil?
          invoice.update_attribute(:paid, true)
          invoice.update_attribute(:amount_paid, self.amount)
        end
      elsif client.account_balance_as_at(as_at,target_currency) > 0.5 and client.credits_total_as_at(as_at,target_currency) > 0
        puts("balance is #{client.account_balance_as_at(as_at,target_currency)} and credits are #{client.credits_total_as_at(as_at,target_currency)}")
        self.update_attribute(:status, 'Partly Paid')
      end
    end
  end

  private

  def generate_qrcode
    # qr_url = url_for(controller: 'accounts',
    #         action: 'show',
    #         id: self.id,
    #         only_path: false,
    #         host: 'localhost',
    #         source: 'qr_code'
    #   )

    qrcode = RQRCode::QRCode.new("#{invoice.client.tenant.company_name} license for #{invoice.client.name} Expiry Date: #{expiry_date.strftime("%d %b %Y")}")

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

  private

  def license_expiry
    # get the license option count by
    if license_option.count_by == 'days'
      self.expiry_date = self.renewal_date.to_date + (self.special_days.to_i - 1)
    else
      self.expiry_date = self.renewal_date.to_date + (license_option.months.months)
    end
  end

  def populate_client
    if self.client_id.nil?
      # unless self.invoice_id.nil?
      #   puts("*********** please populate client id with #{self.invoice_id}")
      #   self.client_id = self.invoice.client_id 
      # else
      #   puts("*************** invoice id is nil")
      # end
      self.client_id = invoice.client_id
    end
  end

  def amount_cannot_be_zero
    errors.add(:amount, "cannot be zero.") if self.amount.nil? || self.amount <= 0
  end
end

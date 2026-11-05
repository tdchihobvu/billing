class Tenant < ApplicationRecord
  belongs_to :tenant_category
  has_many :system_settings
  has_many :clients
  has_many :banks
  has_many :quotations, through: :clients
  has_many :invoices, through: :clients
  has_many :receipts, through: :clients
  has_many :transactions, through: :clients
  has_many :goods_receiveds
  has_many :regional_offices
  has_many :users
  has_many :tarrifs
  has_many :devices
  has_many :shifts, through: :devices
  has_many :industries
  
  has_and_belongs_to_many :system_modules

  before_validation :generate_tenantid

  validates :company_name, uniqueness: true, presence: true
  validates :tenant_category_id, presence: true
  validates :registration_number, :bp_number, presence: true, :uniqueness => { :allow_blank => false }
  validates :vat_number, :uniqueness => { :allow_blank => true }

  accepts_nested_attributes_for :system_settings, allow_destroy: true, reject_if: proc { |attributes| attributes['config_key_id'].blank? }

  def system_setting_value(key_name)
    config_key = ConfigKey.find_by(name: key_name)
    return nil unless config_key

    system_settings.find_by(config_key_id: config_key.id)&.config_value
  end

  def attach_invoice_to_receipt?
    system_setting_value("Attach Invoice to Receipt").to_s.upcase == "YES"
  end

  
  private

  def generate_tenantid
    if self.tenantid.nil?
      number = Random.random_number(100000)
      self.tenantid = number unless Tenant.where(tenantid: number).exists?
    end 
  end

end

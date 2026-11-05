class InvoiceItem < ApplicationRecord
  belongs_to :invoice

  validate :unit_price_cannot_be_zero

  before_save :calc_line_total

  scope :active, -> {where(deleted: false)}

  def vat_type
    VatType.find(self.vat_type_id)
  end

  def net_total
    self.net_price.round(2).to_f * self.quantity
  end

  private

  def calc_line_total
    config_key = ConfigKey.find_by(name: "Product Pricing")
    # product_pricing = SystemSetting.find_by(config_key_id: config_key.id).config_value
    rate = vat_type.rate
    # calculate net price
    if invoice.product_pricing == "inclusive"
      net_price = self.unit_price.to_f/(1 + (rate.to_f/100))
      vat = self.unit_price.to_f - net_price
      self.net_price = net_price
      self.vat = vat
    elsif  invoice.product_pricing == "exclusive"
      net_price = self.unit_price
      vat = net_price.to_f * (rate.to_f/100)
      self.net_price = net_price
      self.vat = vat
    elsif
      net_price = self.unit_price
      vat = 0
      self.net_price = net_price
      self.vat = vat
    end
    self.line_vat = quantity.to_i * vat.to_f
    self.line_total = quantity.to_i * (net_price.to_f + vat.to_f)
  end

  def unit_price_cannot_be_zero
    errors.add(:unit_price, 'cannot be zero') if unit_price.nil? || unit_price <= 0
  end
end

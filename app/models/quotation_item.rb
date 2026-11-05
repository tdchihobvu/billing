class QuotationItem < ApplicationRecord
  belongs_to :quotation

  before_save :calculate_vat

  def vat_type
    VatType.find(self.vat_type_id)
  end

  def net_line_total
    t = 0
    t = self.net_price.to_f * self.quantity.to_f
    puts("**** calculate net price is #{net_price} with total spr #{sprintf("%0.02f",t)}")
    t
  end

  private

  def calculate_vat
    v = 0
    net = self.unit_price
    # check whether pricing includes VAT or not
    # product_pricing = SystemSetting.find_by(tenant_id: quotation.client.tenant_id, config_key_id: ConfigKey.find_by(name: "product Pricing"))
    rate = vat_type.rate
    unless quotation.product_pricing.nil?
      if quotation.product_pricing == 'inclusive'
        net = self.unit_price.to_f/(1 + (rate.to_f/100))
        v = self.unit_price.to_f - net.to_f
      else
        puts("rate is #{rate}")
        v = self.unit_price.to_f * rate.to_f/100
        puts("vat is #{v}")
      end
    end
    self.net_price = net
    self.vat = v
    self.line_vat = v * self.quantity.to_f
    self.line_total = quantity.to_i * (net.to_f + v.to_f)
  end
end

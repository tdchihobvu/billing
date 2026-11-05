class Product < ApplicationRecord
  belongs_to :brand
  belongs_to :measuring_unit
  belongs_to :product_category
  belongs_to :product_type
  belongs_to :vat_type

end

class RegionalOffice < ApplicationRecord
  belongs_to :region
  belongs_to :tenant
end

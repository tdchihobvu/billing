class District < ApplicationRecord
  belongs_to :region

  def region_name
    self.region.name
  end
end

class Branch < ApplicationRecord
  belongs_to :client
  belongs_to :license_category
  belongs_to :license_option
  has_and_belongs_to_many :invoices

  before_validation :populate_name

  scope :active, -> {where(active: true)}

  def full_address
    "#{address_1}, #{location}, #{city}"
  end

  def branch_name
    "#{client.name} #{location}"
  end

  private

  def populate_name
    self.name = "#{address_1} #{location} #{city}"
  end
end

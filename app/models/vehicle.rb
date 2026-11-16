# A client's motor vehicle. Each vehicle covered by an approved licence gets its own licence disc.
class Vehicle < ApplicationRecord
  belongs_to :tenant
  belongs_to :client
  has_and_belongs_to_many :licenses

  before_validation :normalise_registration
  validates :registration_number, presence: true, length: { maximum: 20 },
                                  uniqueness: { scope: :tenant_id, message: "is already registered to a client" }
  validate :client_belongs_to_tenant

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:registration_number) }

  def label
    [registration_number, make_model.presence].compact.join(" · ")
  end

  private

  # "abx8409" and "ABX  8409" are the same plate: store as upper case with single spaces.
  def normalise_registration
    self.registration_number = registration_number.to_s.upcase.squish.presence
  end

  def client_belongs_to_tenant
    errors.add(:client, "must belong to this company") if client && tenant_id && client.tenant_id != tenant_id
  end
end

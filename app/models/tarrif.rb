class Tarrif < ApplicationRecord
  belongs_to :industry
  belongs_to :tenant

  validate :amount_cannot_be_zero

  def validate
    self.name = self.industry.name
  end

  private

  def amount_cannot_be_zero
    errors.add(:amount, 'cannot be zero.') if amount.nil? || amount <= 0
  end

end

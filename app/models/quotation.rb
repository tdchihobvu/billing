class Quotation < ApplicationRecord
  belongs_to :client
  belongs_to :currency
  belongs_to :user
  has_many :quotation_items, dependent: :destroy

  has_rich_text :quotation_terms

  validates :validity, presence: true
  validate :validity_cannot_be_zero

  accepts_nested_attributes_for :quotation_items, allow_destroy: true, reject_if: proc { |attributes| attributes['description'].blank? }

  def bank
    Bank.find(self.bank_id)
  end
  
  def sub_total
    quotation_items.sum(&:net_line_total)
  end

  def vat
    quotation_items.sum(:line_vat)
  end

  def total
    sub_total + vat
  end

  private 

  def validity_cannot_be_zero
    errors.add(:validity, "cannot be zero.") if validity.nil? || validity <= 0
  end

end

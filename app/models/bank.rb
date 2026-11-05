class Bank < ApplicationRecord

  belongs_to :tenant
  belongs_to :currency
  has_and_belongs_to_many :invoices

  validates :account_number, :bank_name, :description, presence: true
  validates :account_number, uniqueness: { scope: [:bank_name, :tenant_id], message: "Account Number already exists" }

  scope :active, -> {where(active: true)}

  def invoice_title
    "#{bank_name} #{currency.name}"
  end

  def status
    return 'Active' if active == true
    return 'Inactive' if active == false
  end

end

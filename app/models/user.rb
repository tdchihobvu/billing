class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  belongs_to :tenant
  has_many :transactions
  has_many :exchange_rates
  has_many :devices
  has_many :invoices
  has_many :receipts

  validates :tenant_id, presence: true
  validates :firstname, :lastname, :username, presence: true

  validates :role, inclusion: { in: ['cashier','supervisor','manager','admin','superadmin']}

  def fullname
    "#{firstname} #{lastname}"
  end

end

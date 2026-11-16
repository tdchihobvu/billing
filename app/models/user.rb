class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  attr_accessor :temporary_password

  before_save :clear_password_change_flag

  belongs_to :tenant
  has_many :transactions
  has_many :exchange_rates
  has_many :devices
  has_many :invoices
  has_many :receipts

  validates :tenant_id, presence: true
  validates :firstname, :lastname, :username, presence: true

  validates :role, presence: true
  validate :role_exists
  validate :password_strength, if: -> { password.present? }

  # Shown next to every password field, so people know the rules before they type.
  PASSWORD_RULES = "At least 8 characters, with letters and numbers. Not your username, and not a common password.".freeze
  COMMON_PASSWORDS = %w[password password1 passw0rd 12345678 123456789 1234567890 qwerty123 qwertyui
                        abc12345 abcd1234 iloveyou letmein1 welcome1 zimura123 zimura2026 admin123 changeme].freeze

  # A temporary password that meets the rules (used by an admin password reset).
  def self.temporary_password
    loop do
      candidate = SecureRandom.alphanumeric(10)
      return candidate if candidate.match?(/[A-Za-z]/) && candidate.match?(/\d/)
    end
  end

  def fullname
    "#{firstname} #{lastname}"
  end

  def superadmin?
    role == "superadmin"
  end

  # The Role record behind users.role (permissions live there).
  def role_record
    return @role_record if defined?(@role_record) && @role_record&.key == role
    @role_record = tenant && Role.for(tenant).find_by(key: role)
  end

  def role_name
    role_record&.name || role.to_s.humanize
  end

  # May this user do it? A Super admin may do everything.
  def can?(permission)
    return true if superadmin?
    @granted ||= {}
    @granted.fetch(permission) { @granted[permission] = role_record&.allows?(permission) || false }
  end

  # Forget remembered permissions when the record is reloaded (role or its permissions may have changed).
  def reload(*)
    @granted = nil
    remove_instance_variable(:@role_record) if defined?(@role_record)
    super
  end

  def can_any?(*permissions)
    permissions.flatten.any? { |p| can?(p) }
  end

  # Confirms full payment on licences (first approval stage).
  def finance_officer?
    !superadmin? && can?("licenses.approve_finance")
  end

  # Gives final approval on licences (a Super admin is the backup).
  def final_approver?
    can?("licenses.approve_final")
  end

  # Can open the licence approvals queue.
  def sees_license_approvals?
    can_any?("licenses.approvals_view", "licenses.approve_finance", "licenses.approve_final")
  end


  def using_default_password?
    valid_password?("#{username.downcase}!@#")
  end

  private

  # Devise checks the length (8 to 128); these are the other rules. Existing passwords
  # are not affected until they are next changed.
  def password_strength
    pw = password.to_s
    name = username.to_s.downcase.strip
    errors.add(:password, "must include at least one letter") unless pw.match?(/[A-Za-z]/)
    errors.add(:password, "must include at least one number") unless pw.match?(/\d/)
    if name.length >= 3 && pw.downcase.include?(name)
      errors.add(:password, "can't contain your username")
    end
    errors.add(:password, "is too common. Choose something harder to guess") if COMMON_PASSWORDS.include?(pw.downcase)
    errors.add(:password, "can't be the same character repeated") if pw.chars.uniq.size <= 2
  end

  def role_exists
    return if role.blank? || tenant.nil?
    errors.add(:role, "is not one of this company's roles") unless Role.for(tenant).exists?(key: role)
  end

  def clear_password_change_flag
    self.must_change_password = false if will_save_change_to_encrypted_password? && !temporary_password
  end
end

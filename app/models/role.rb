# A role groups permissions (see Permission). Users hold a role by its key (users.role).
# Built-in roles can be renamed and their permissions changed, but not deleted.
# The Super admin role always has every permission and cannot be changed.
class Role < ApplicationRecord
  belongs_to :tenant

  BUILT_IN = {
    "superadmin" => { name: "Super admin", position: 1, description: "Runs the system: people, roles, settings, and everything else." },
    "admin" => { name: "Admin", position: 2, description: "Runs day-to-day administration, settings and people. Follows licence approvals." },
    "manager" => { name: "Manager", position: 3, description: "Oversees sales and gives the final approval on licences." },
    "finance" => { name: "Finance Officer", position: 4, description: "Checks payments and confirms them before licences are approved." },
    "supervisor" => { name: "Supervisor", position: 5, description: "Checks Inspectors' work: invoices, receipts and reports." },
    "cashier" => { name: "Inspector", position: 6, description: "Visits clients, raises licence invoices, records receipts and prints approved licences." }
  }.freeze

  # Starting permissions, chosen to fit each job. A Super admin can change them on the Roles page.
  DEFAULT_PERMISSIONS = {
    "admin" => Permission::KEYS - %w[roles.manage licenses.approve_finance licenses.approve_final],
    "manager" => %w[clients.view clients.manage clients.journals invoices.view invoices.create invoices.edit invoices.delete invoices.discount
                    invoices.credit_notes invoices.reminders receipts.view receipts.create receipts.edit licenses.view licenses.generate
                    licenses.print licenses.approve_final reports.view settings.exchange_rates users.view],
    "finance" => %w[clients.view clients.journals invoices.view invoices.credit_notes receipts.view receipts.create receipts.edit
                    licenses.view licenses.approve_finance reports.view settings.exchange_rates],
    "supervisor" => %w[clients.view clients.manage invoices.view invoices.create invoices.edit invoices.reminders receipts.view receipts.create
                       licenses.view licenses.generate licenses.print licenses.approvals_view reports.view],
    "cashier" => %w[clients.view clients.manage invoices.view invoices.create receipts.view receipts.create
                    licenses.view licenses.generate licenses.print reports.view]
  }.freeze

  validates :name, presence: true, length: { maximum: 60 }
  validates :key, presence: true, uniqueness: { scope: :tenant_id }, format: { with: /\A[a-z0-9_]+\z/ }
  validates :name, uniqueness: { scope: :tenant_id, case_sensitive: false }
  validate :permissions_are_known

  before_validation :normalise
  before_destroy :refuse_if_in_use

  scope :ordered, -> { order(:position, :name) }

  # Every company gets the built-in roles; missing ones are added on first use.
  def self.for(tenant)
    ensure_defaults!(tenant)
    where(tenant_id: tenant.id).ordered
  end

  def self.ensure_defaults!(tenant)
    existing = where(tenant_id: tenant.id).pluck(:key)
    (BUILT_IN.keys - existing).each do |key|
      info = BUILT_IN[key]
      create!(tenant_id: tenant.id, key: key, name: info[:name], description: info[:description], position: info[:position],
              built_in: true, permissions: key == "superadmin" ? Permission::KEYS : DEFAULT_PERMISSIONS.fetch(key, []))
    end
  end

  def superadmin?
    key == "superadmin"
  end

  def allows?(permission)
    superadmin? || Array(permissions).include?(permission)
  end

  def users
    User.where(tenant_id: tenant_id, role: key)
  end

  private

  def normalise
    self.name = name.to_s.squish
    self.key = name.to_s.parameterize(separator: "_").first(40) if key.blank? && name.present?
    # A new role never takes over a built-in or existing key (users hold roles by key).
    if new_record? && !built_in && key.present? && (BUILT_IN.key?(key) || Role.where(tenant_id: tenant_id, key: key).exists?)
      self.key = "#{key.first(33)}_#{SecureRandom.hex(3)}"
    end
    self.permissions = superadmin? ? Permission::KEYS : (Array(permissions).map(&:to_s) & Permission::KEYS) - %w[roles.manage]
  end

  def permissions_are_known
    unknown = Array(permissions) - Permission::KEYS
    errors.add(:permissions, "include unknown entries: #{unknown.join(', ')}") if unknown.any?
  end

  def refuse_if_in_use
    if built_in
      errors.add(:base, "Built-in roles can't be deleted.")
    elsif users.exists?
      errors.add(:base, "Move the #{users.count} #{'person'.pluralize(users.count)} in this role to another role first.")
    end
    throw :abort if errors.any?
  end
end

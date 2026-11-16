# Everything a role can be allowed to do, in plain words, grouped by area of the system.
# Each permission lists the pages/actions it opens ("controller#action", or "controller" for all
# of a controller). Authorization (app/controllers/concerns/authorization.rb) enforces this map.
class Permission
  Item = Struct.new(:key, :group, :label, :hint, :actions, :superadmin_only, :view, keyword_init: true)

  GROUPS = [
    ["clients", "Clients", "fa-store"],
    ["invoices", "Invoices", "fa-file-invoice-dollar"],
    ["receipts", "Receipting", "fa-receipt"],
    ["licenses", "Licensing", "fa-stamp"],
    ["reports", "Reports", "fa-chart-line"],
    ["settings", "Settings", "fa-sliders-h"],
    ["users", "People and roles", "fa-users"]
  ].freeze

  ALL = [
    # Clients
    Item.new(key: "clients.view", view: true, group: "clients", label: "View clients and statements",
             hint: "Client list, client details, statements and printing a statement.",
             actions: %w[clients#index clients#show clients#account_statement clients#print_by_date]),
    Item.new(key: "clients.manage", group: "clients", label: "Add and edit clients",
             hint: "New clients, editing details, branches and branch uploads, deleting clients.",
             actions: %w[clients#new clients#create clients#edit clients#update clients#destroy clients#add_branches clients#upload_branches clients#delete_branch
                         vehicles#create vehicles#update vehicles#destroy]),
    Item.new(key: "clients.journals", group: "clients", label: "Take-on balances and journals",
             hint: "Post opening balances and journals, and reset a client's statement.",
             actions: %w[clients#takeon_balances clients#save_journal clients#edit_journal clients#update_journal clients#reset_statement]),

    # Invoices
    Item.new(key: "invoices.view", view: true, group: "invoices", label: "View and print invoices",
             hint: "Invoice lists, invoice details, printing invoices, delivery notes and credit notes.",
             actions: %w[invoices#index invoices#show invoices#print invoices#receipt invoices#delivery_note invoices#inactive invoices#credit_notes invoices#print_credit_note quotations#index quotations#show quotations#print]),
    Item.new(key: "invoices.create", group: "invoices", label: "Raise invoices",
             hint: "New sales and licence invoices, proformas, duplicates, quotations and fiscalising.",
             actions: %w[invoices#new invoices#create invoices#license invoices#proforma invoices#duplicate invoices#fiscalise invoices#save_fiscal_invoice quotations#new quotations#create]),
    Item.new(key: "invoices.edit", group: "invoices", label: "Edit invoices",
             hint: "Change invoices, assign branches and post setoffs.",
             actions: %w[invoices#edit invoices#update invoices#edit_license invoices#assign_branches invoices#setoff quotations#edit quotations#update]),
    Item.new(key: "invoices.delete", group: "invoices", label: "Delete or void invoices",
             hint: "Move invoices to trash, void them, and approve or reject void requests sent from phones. Voided invoices drop off balances and reports.",
             actions: %w[invoices#destroy invoices#disable invoices#void_invoice quotations#destroy
                         void_requests#index void_requests#approve void_requests#reject]),
    Item.new(key: "invoices.discount", group: "invoices", label: "Apply discounts",
             hint: "Enter an approved discount on an invoice.", actions: []),
    Item.new(key: "invoices.credit_notes", group: "invoices", label: "Raise credit notes",
             hint: "Credit an invoice with a credit note.", actions: %w[invoices#credit_note invoices#save_credit_note]),
    Item.new(key: "invoices.reminders", group: "invoices", label: "Send payment reminders",
             hint: "SMS and email reminders for unpaid invoices.", actions: %w[invoices#sms_reminder invoices#email_reminder]),

    # Receipting
    Item.new(key: "receipts.view", view: true, group: "receipts", label: "View and print receipts",
             hint: "Receipt lists, receipt details, printing receipts and shifts.",
             actions: %w[receipts#index receipts#show receipts#print receipts#shifts]),
    Item.new(key: "receipts.create", group: "receipts", label: "Record receipts",
             hint: "Record payments against invoices or a client's account.",
             actions: %w[receipts#new receipts#record_receipt receipts#invoices receipts#create clients#post_receipt]),
    Item.new(key: "receipts.edit", group: "receipts", label: "Edit and void receipts",
             hint: "Change or void a receipt, and close shifts.", actions: %w[receipts#edit receipts#update receipts#destroy receipts#close_shift]),

    # Licensing
    Item.new(key: "licenses.view", view: true, group: "licenses", label: "View licences",
             hint: "Licence lists and licence details.", actions: %w[licenses#index licenses#show]),
    Item.new(key: "licenses.generate", group: "licenses", label: "Generate licences",
             hint: "Create, edit and delete licences from paid invoices.",
             actions: %w[licenses#new licenses#generate licenses#generate_new licenses#create licenses#edit licenses#update licenses#destroy licenses#assign_vehicles]),
    Item.new(key: "licenses.print", group: "licenses", label: "Print licences",
             hint: "Print approved licences, single, for every branch, or as vehicle licence discs.",
             actions: %w[licenses#print licenses#print_plain licenses#print_multiple licenses#branch_license licenses#download_all licenses#vehicle_discs]),
    Item.new(key: "licenses.approvals_view", group: "licenses", label: "See the approval queue",
             hint: "Follow licences through approval without acting on them.", actions: %w[license_approvals#index license_approvals#show]),
    Item.new(key: "licenses.approve_finance", group: "licenses", label: "Confirm payment on licences (Finance)",
             hint: "First approval: confirm full payment was received, or reject.",
             actions: %w[license_approvals#index license_approvals#show license_approvals#approve license_approvals#reject license_approvals#resubmit]),
    Item.new(key: "licenses.approve_final", group: "licenses", label: "Give final approval on licences (Manager)",
             hint: "Second approval: release the licence for printing, or return it to Finance.",
             actions: %w[license_approvals#index license_approvals#show license_approvals#approve license_approvals#reject]),

    # Reports
    Item.new(key: "reports.view", view: true, group: "reports", label: "View reports and exports",
             hint: "Sales, collections, overdue invoices, expiring licences, Inspector report and their Excel files.",
             actions: %w[reports welcome#dashboard]),

    # Settings
    Item.new(key: "settings.exchange_rates", group: "settings", label: "Set exchange rates",
             hint: "Enter and edit exchange rates used for other currencies.", actions: %w[exchange_rates]),
    Item.new(key: "settings.manage", group: "settings", label: "Change settings and lists",
             hint: "System settings, banks, currencies, payment forms, licence categories, tariffs, taxes, offices, apps and devices.",
             actions: %w[system_settings banks currencies payment_forms license_categories license_options industries tarrifs client_types districts vat_types regional_offices devices setting_categories inventory products brands suppliers goods_receiveds stock_counts measuring_units product_types product_categories tenant_locales welcome#refresh welcome#register_device]),

    Item.new(key: "system.health", group: "settings", label: "View system health and fix balances",
             hint: "See problems the system logged (payments not applied, failed exports, refused phone uploads) and run the balance check.",
             actions: %w[system_health]),

    # People and roles
    Item.new(key: "users.view", view: true, group: "users", label: "View people",
             hint: "See who uses the system and their roles.", actions: %w[user_management#index user_management#details]),
    Item.new(key: "users.manage", group: "users", label: "Add and edit people",
             hint: "Create users, change their details and role, and reset passwords. Only a Super admin can make someone a Super admin.",
             actions: %w[user_management#new user_management#save user_management#edit user_management#update user_management#reset]),
    Item.new(key: "roles.manage", group: "users", label: "Manage roles and permissions",
             hint: "Create roles and decide what each can do. Super admin only.", actions: %w[roles], superadmin_only: true)
  ].freeze

  BY_KEY = ALL.index_by(&:key).freeze
  KEYS = ALL.map(&:key).freeze

  # "controller#action" (or "controller") => keys that open it. Any one of them is enough.
  ACTION_INDEX = ALL.each_with_object(Hash.new { |h, k| h[k] = [] }) do |item, index|
    item.actions.each { |a| index[a] << item.key }
  end.freeze

  def self.for_action(controller, action)
    ACTION_INDEX.fetch("#{controller}##{action}") { ACTION_INDEX.fetch(controller, []) }
  end

  def self.grouped
    GROUPS.map { |key, label, icon| [key, label, icon, ALL.select { |p| p.group == key }] }
  end

  # How much of an area a set of permissions opens: :none, :view (only the area's "view"
  # permission), :full (everything a role can be given there) or :custom.
  def self.access_level(granted, items)
    keys = items.map(&:key)
    have = keys & Array(granted)
    view_keys = items.select(&:view).map(&:key)
    return :none if have.empty?
    return :full if have.size == keys.size
    return :view if view_keys.any? && have.sort == view_keys.sort

    :custom
  end

  ACCESS_LABELS = { none: "No access", view: "View only", full: "Full access", custom: "Custom" }.freeze

  def self.label(key)
    BY_KEY[key]&.label || key
  end
end

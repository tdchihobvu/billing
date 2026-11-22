class Client < ApplicationRecord
  belongs_to :client_type
  belongs_to :industry
  belongs_to :tenant
  belongs_to :currency
  has_many :quotations
  has_many :invoices#, -> {where(deleted: false)}
  has_many :licenses, through: :invoices
  has_many :transactions#, -> {where(deleted: false)}
  has_many :receipts#, -> {where(deleted: false)}
  has_many :branches, dependent: :destroy
  has_many :vehicles, dependent: :destroy
  # has_many :journal_debits, through: :transactions, class: 'transaction', -> {where(journal: true, debit: true)}
  # has_many :journal_credits, through: :transactions, class: 'transaction', -> {where(journal: true, debit: false)}

  accepts_nested_attributes_for :branches, allow_destroy: true, reject_if: proc { |attributes| attributes['address_1'].blank? }

  validates :name, uniqueness: {
      scope: :tenant_id,
      case_sensitive: false,
      message: "Client already exists"
    }
  validates :name, :client_type_id, :industry_id, :address_1, :location, :city, :country, presence: true

  scope :active, -> {where(active: true)}

  # An account owing no more than this is settled (the rule License#validate_paid uses).
  SETTLED_WITHIN = 0.5.to_d

  def contact_person
    cp_name
  end

  def business_nature
    ""
    unless industry.nil?
      industry.name
    end
  end

  def default_phone
    p = self.phone  
    unless p.nil?
      p = self.mobile
    end
    p
  end

  def client_address
    addr = ""
    unless self.address_2.nil? || self.address_2.empty?
      addr = "#{address_1}, #{address_2}, #{city}, #{country}"
    else
      addr = "#{address_1}, #{city}, #{country}"
    end
    addr
  end

  def self.search(search)
    return [] if search.blank?

    # Each word matches separately ("bottle store" finds "Bottle Gumbo Store"); % and _ typed by the user are literal.
    words = search.to_s.split.map { |w| sanitize_sql_like(w) }
    Client.where("name ILIKE ?", "%#{words.join('%')}%").order(name: :asc)
  end

  def journal_debits
    transactions.where(journal: true, debit: true)
  end

  def journal_credits
    transactions.where(journal: true, debit: false)
  end

  def settle_licenses_from_statement
    reconcile_invoice_balances
    licenses.active.where(paid: false).find_each(&:validate_paid)
  end

  # The statement is the truth for what a client owes. Money that reaches the account
  # without paying one of their own invoices (receipts on account, credit journals,
  # receipts attached to another client's invoice) is spread over the client's unpaid
  # invoices, oldest first. Invoice balances then add up to the statement everywhere:
  # invoice lists, reports, licences and the inspectors' phones.
  def reconcile_invoice_balances
    key = :"reconciling_client_#{id}"
    return if Thread.current[key]

    Thread.current[key] = true
    update_statement(tenant)
    target = currency
    owed = transactions.where(deleted: false).to_a.sum { |t| (t.debit? ? 1 : -1) * t.rated_amount(target).to_d }
    # Cents left over from currency conversion: the licence check already treats an
    # account within this amount as settled, so the invoices follow the same rule.
    owed = 0.to_d if owed <= SETTLED_WITHIN

    rows = invoices.sales.order(:invoice_date, :id).to_a.map do |inv|
      total = inv.total.to_d
      unpaid = [total - inv.own_receipts_total.to_d, 0].max
      factor = total.zero? ? 1.to_d : inv.rated_invoice_total(target).to_d / total # invoice currency -> statement currency
      [inv, unpaid, factor]
    end

    spare = rows.sum { |_, unpaid, factor| unpaid * factor } - [owed, 0].max
    rows.each do |inv, unpaid, factor|
      share = spare > 0.01 ? [unpaid * factor, spare].min : 0.to_d
      spare -= share
      inv.apply_account_credit(factor.zero? ? 0 : (share / factor).round(2))
    end
  ensure
    Thread.current[key] = nil
  end

  def update_statement(tenant)
    config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
    exchange_rate_update_frequency = tenant.system_settings.find_by(config_key_id: config.id).config_value
    # get invoices and post them as debits
    invoices.active.each do |i|
      i.sync_balance
      post_statement_line("Invoices", i, debit: true, date: i.invoice_date, reference: i.invoice_number,
                                         description: i.statement_description, amount: i.invoice_total)
    end
    # get receipts and post them as credits
    receipts.active.each do |r|
      post_statement_line("Receipts", r, debit: false, date: r.transaction_date, reference: r.reference_number,
                                         description: r.description, amount: r.amount)
    end
    sync_deleted_statement_lines
  end

  # One statement line per invoice or receipt, kept equal to the document: an edited
  # amount, currency or rate used to leave the old figure on the statement.
  def post_statement_line(source, doc, debit:, date:, reference:, description:, amount:)
    line = Transaction.where(client_id: id, source: source, source_id: doc.id, journal: [false, nil]).order(:id).first
    if line.nil?
      Transaction.create(client_id: id, transaction_date: date, reference_number: reference, description: description,
                         amount: amount, debit: debit, user_id: doc.user_id, source: source, source_id: doc.id,
                         tenant_id: doc.tenant_id, currency_id: doc.currency_id, rate: doc.rate)
      return
    end

    figures = { amount: amount, currency_id: doc.currency_id, rate: doc.rate }
    changed = figures.reject { |key, value| line[key].to_d == value.to_d }
    line.update_columns(changed.merge(updated_at: Time.current)) if changed.any?
  end

  # Hides statement lines whose invoice or receipt was deleted or voided, and shows them
  # again if it was restored. Journals are entered by hand and are left alone.
  def sync_deleted_statement_lines
    lines = Transaction.where(client_id: id, journal: [false, nil])
    now = Time.current
    { "Invoices" => invoices, "Receipts" => receipts }.each do |source, documents|
      lines.where(source: source, deleted: [false, nil], source_id: documents.where(deleted: true).select(:id))
           .update_all(deleted: true, updated_at: now)
      lines.where(source: source, deleted: true, source_id: documents.where(deleted: false).select(:id))
           .update_all(deleted: false, updated_at: now)
    end
  end

  def reset_statement
    ActiveRecord::Base.connection.execute(<<~SQL)
      DELETE FROM transactions WHERE client_id = #{self.id} AND journal = false;
    SQL
  end

  def default_currency
    Currency.find(self.currency_id).name
  end

  # Statement Balances

  def update_client_balances
    # base_currency = Currency.find_by(name: 'USD')
    # balance = 0
    # receipts = self.receipts.active.sum(&:amount_paid)
    # invoices = self.invoices.active.sum(&:total)
    # balance = invoices - receipts
    # if self.update(total_invoices: invoices, total_receipts: receipts, balance: balance, last_statement_update: Time.now)
    #   puts("client #{self.name} balances updated.")
    # end
  end

  def debits_total_as_at(as_at,target_currency)
    s = 0
    s += invoices.active.where("invoice_date <= '#{as_at}'").sum { |invoice| invoice.rated_invoice_total(target_currency) }.to_f
    # add journals
    journal_debits.each do |j|
      s += j.rated_amount(target_currency)
    end
    s
  end

  def credits_total_as_at(as_at,target_currency)
    p = 0
    p += receipts.active.where("transaction_date <= '#{as_at}'").sum { |receipt| receipt.rated_amount(target_currency) }.to_f
    # add journals
    journal_credits.each do |j|
      p += j.rated_amount(target_currency)
    end
    p
  end

  def account_balance_as_at(as_at,target_currency)
    debits_total_as_at(as_at,target_currency).to_f - credits_total_as_at(as_at,target_currency).to_f #receipts.active.sum(:amount)
  end

  def self.import_branches(client_id,file)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(1)
    (2..spreadsheet.last_row).each do |i|
      row = Hash[[header, spreadsheet.row(i)].transpose]
      nn = "#{row["Street Address"]} #{row["Location"]} #{row["City"]}"
      cc = self.find(client_id)
      puts(nn)
      unless row.nil?
        unless Branch.exists?(client_id: client_id, name: nn)
          Branch.create(client_id: client_id, name: nn, address_1: row["Street Address"], location: row["Location"], city: row["City"], tenant_id: cc.id, license_category_id: 1, license_option_id: 1)
        end
      end
    end
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Roo::Csv.new(file.path, nil, :ignore)
    when ".xls" then Roo::Excel.new(file.path, packed: false, file_warning: :ignore)
    when ".xlsx" then Roo::Excelx.new(file.path, packed: false, file_warning: :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end  

end

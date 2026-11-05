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
    if search 
      Client.where("name LIKE '%#{search}%'").order("name asc")
    else
      []
    end
  end

  def journal_debits
    transactions.where(journal: true, debit: true)
  end

  def journal_credits
    transactions.where(journal: true, debit: false)
  end

  def update_statement(tenant)
    config = ConfigKey.find_by(name: 'Exchange Rate Update Frequency')
    exchange_rate_update_frequency = tenant.system_settings.find_by(config_key_id: config.id).config_value
    # get invoices and post them as debits
    invoices.active.each do |i|
      i.update(amount_paid: i.total_paid, invoice_total: i.total)
      unless i.client.nil?
        transaction_date = i.invoice_date
        unless Transaction.exists?(client_id: i.client_id, source: 'Invoices', source_id: i.id, reference_number: i.invoice_number)
          Transaction.create(
            client_id: i.client_id,
            transaction_date: i.invoice_date,
            reference_number: i.invoice_number,
            description: i.statement_description,
            amount: i.invoice_total,
            debit: true,
            user_id: i.user_id,
            source: 'Invoices',
            source_id: i.id,
            tenant_id: i.tenant_id,
            currency_id: i.currency_id,
            rate: i.rate
            )
        end
      end
    end
    # get receipts and post them as credits
    receipts.active.each do |r|
      unless r.client.nil?
        transaction_date = r.transaction_date
        unless Transaction.exists?(client_id: r.client_id, source: 'Receipts', source_id: r.id, reference_number: r.reference_number)
          Transaction.create(
            client_id: r.client_id,
            transaction_date: r.transaction_date,
            reference_number: r.reference_number,
            description: r.description,
            amount: r.amount,
            debit: false,
            user_id: r.user_id,
            source: 'Receipts',
            source_id: r.id,
            tenant_id: r.tenant_id,
            currency_id: r.currency_id,
            rate: r.rate
            )
        end
      end
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

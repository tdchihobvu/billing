class CreateSystemModules < ActiveRecord::Migration[7.1]
  def change
    create_table :system_modules do |t|
      t.string :name
      t.string :description
    end
    SystemModule.create name: 'Quotations', description: 'Generation of estimates'
    SystemModule.create name: 'Invoicing', description: 'Generation of Invoices'
    SystemModule.create name: 'Receipting', description: 'Manage receipts and collections'
    SystemModule.create name: 'Multicurrency', description: 'Multiple currencies management'
    SystemModule.create name: 'Licensing', description: 'Manages client licenses'
    SystemModule.create name: 'API', description: 'Intgrates with Mobile Application'
    SystemModule.create name: 'Card Management', description: 'Manages membership and cards distribution'
    SystemModule.create name: 'Expenses', description: 'Manages expenses'
    SystemModule.create name: 'Inventory', description: 'Manages stock inventory'
  end
end

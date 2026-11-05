class AddUserFullnameToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :user_fullname, :string
    add_column :receipts, :user_fullname, :string
  end
end

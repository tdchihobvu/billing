class AddOrderNumberToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :order_number, :string
  end
end

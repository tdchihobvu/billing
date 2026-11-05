class AddDescriptionToInvoice < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :description, :string
  end
end

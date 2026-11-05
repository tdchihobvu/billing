class AddInvoiceToLicense < ActiveRecord::Migration[7.1]
  def change
    add_reference :licenses, :invoice, null: false, foreign_key: true
    add_column :licenses, :branch_id, :integer
  end
end

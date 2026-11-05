class AddOrderNumberToQuotation < ActiveRecord::Migration[7.1]
  def change
    add_column :quotations, :order_number, :string
    add_column :quotations, :validity, :integer, null: false
  end
end

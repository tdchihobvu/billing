class AddJournalToTransaction < ActiveRecord::Migration[7.1]
  def change
    add_column :transactions, :journal, :boolean, default: false
  end
end

# The MySQL data includes clients without a mobile number and 11 rows whose
# parent records no longer exist. These foreign keys stay enforced for new
# writes, but NOT VALID lets existing rows survive a dump and restore.
class AlignConstraintsWithMigratedData < ActiveRecord::Migration[7.1]
  FOREIGN_KEYS = [[:clients, :industries], [:invoice_items, :invoices], [:transactions, :clients]].freeze

  def up
    change_column_null :clients, :cp_mobile, true
    FOREIGN_KEYS.each do |from, to|
      remove_foreign_key from, to
      add_foreign_key from, to, validate: false
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "existing data violates the original constraints"
  end
end

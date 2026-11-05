class CreateShifts < ActiveRecord::Migration[7.1]
  def change
    create_table :shifts do |t|
      t.string :shift_id
      t.string :username
      t.integer :region_id
      t.references :tenant, null: false, foreign_key: true
      t.references :device, null: false, foreign_key: true
      t.datetime :start_time
      t.datetime :end_time
      t.boolean :active, default: true
      t.boolean :start_shift_synced, default: false
      t.boolean :close_shift_synced, default: false
      t.decimal :declared_amount, precision: 18, scale: 3, default: 0.000
      t.decimal :cash_collected, precision: 18, scale: 3, default: 0.000
      t.decimal :total_collected, precision: 18, scale: 3, default: 0.000
      t.decimal :total_cashed, precision: 18, scale: 3, default: 0.000
      t.decimal :epayments, precision: 18, scale: 3, default: 0.000
      t.decimal :usd_epayments, precision: 18, scale: 3, default: 0.000
      t.decimal :total_prepaid, precision: 18, scale: 3, default: 0.000
      t.string :shift_supervisor

      t.timestamps
    end
  end
end

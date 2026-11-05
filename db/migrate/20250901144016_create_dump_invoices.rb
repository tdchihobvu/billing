class CreateDumpInvoices < ActiveRecord::Migration[7.1]
  def change
    create_table :dump_invoices do |t|
      t.string :username
      t.string :shiftid
      t.string :district
      t.string :clientname
      t.string :invoicedate
      t.string :invoiceref
      t.string :itemdescription
      t.string :gpslatitude
      t.string :gpslongitude
      t.string :amountdue
      t.string :renwalmonth
      t.string :licenseoption
      t.string :licensecategory
      t.string :licensedays
      t.string :invoicecurrency
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

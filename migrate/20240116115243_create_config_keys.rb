class CreateConfigKeys < ActiveRecord::Migration[7.1]
  def change
    create_table :config_keys do |t|
      t.string :name
      t.belongs_to :setting_category, null: false, foreign_key: true
    end
    ConfigKey.create name: "Quote No.", setting_category_id: 1
    ConfigKey.create name: "Invoice No.", setting_category_id: 1
    ConfigKey.create name: "Receipt No.", setting_category_id: 1
    ConfigKey.create name: "Invoice Title", setting_category_id: 1
    ConfigKey.create name: "Proforma Invoice No.", setting_category_id: 1
    ConfigKey.create name: "Invoice Numbers Generation", setting_category_id: 1
    ConfigKey.create name: "Invoice Template", setting_category_id: 1
    ConfigKey.create name: "Product Pricing", setting_category_id: 1
  end
end


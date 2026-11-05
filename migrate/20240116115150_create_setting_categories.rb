class CreateSettingCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :setting_categories do |t|
      t.string :name
    end
    SettingCategory.create name: "General"
    SettingCategory.create name: "Formats"
    SettingCategory.create name: "Rates"
  end
end

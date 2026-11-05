class AddCountByToLicenseOption < ActiveRecord::Migration[7.1]
  def change
    add_column :license_options, :count_by, :string, default: 'months'
  end
end

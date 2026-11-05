class CreateContactPeople < ActiveRecord::Migration[7.1]
  def change
    create_table :contact_people do |t|
      t.belongs_to :tenant, null: false, foreign_key: true
      t.string :firstname
      t.string :lastname
      t.string :designation
      t.string :email
      t.string :mobile_1
      t.string :mobile_2

      t.timestamps
    end
  end
end

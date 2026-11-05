class CreateClientTypes < ActiveRecord::Migration[7.1]
  def change
    create_table :client_types do |t|
      t.string :name, null: false

    end
    ClientType.create name: "Individual"
    ClientType.create name: "Corporate"
    ClientType.create name: "Government"
  end
end

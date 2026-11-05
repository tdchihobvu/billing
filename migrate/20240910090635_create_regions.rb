class CreateRegions < ActiveRecord::Migration[7.1]
  def change
    create_table :regions do |t|
      t.string :name

      t.timestamps
    end

    Region.create name: "Harare Metropolitan"
    Region.create name: "Bulawayo Metropolitan"
    Region.create name: "Mashonalad West"
    Region.create name: "Mashonalad East"
    Region.create name: "Mashonalad Central"
    Region.create name: "Manicaland"
    Region.create name: "Midlands"
    Region.create name: "Matebeleland South"
    Region.create name: "Matebeleland North"
    Region.create name: "Masvingo"

  end
end

class CreateIndustries < ActiveRecord::Migration[7.1]
  def change
    create_table :industries do |t|
      t.string :name, null: false
    end

    # Industry.create name: "Real Estate & Construction"
    # Industry.create name: "Manufacturing"
    # Industry.create name: "Energy"
    # Industry.create name: "Education"
    # Industry.create name: "Information Technology"
    # Industry.create name: "Retail & Consumer Goods"
    # Industry.create name: "Health Care"
    # Industry.create name: "Telecommunications"
    # Industry.create name: "Insurance"
    # Industry.create name: "Financial Services"
    # Industry.create name: "Automotive"
    # Industry.create name: "Mining & Agriculture"
    # Industry.create name: "Airlines"
    # Industry.create name: "Not for Profit"
    # Industry.create name: "Transport & Logistics"
    # Industry.create name: "Chemicals"
    # Industry.create name: "Packaging"
    # Industry.create name: "Consumer Services"
    # Industry.create name: "Utilities"
    # Industry.create name: "Pharmaceuticals & Biotechnology"
    # Industry.create name: "Public Sector"
    # Industry.create name: "Hospitality"
    # Industry.create name: "Audit & Accounting"
  end
end

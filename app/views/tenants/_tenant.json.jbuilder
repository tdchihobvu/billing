json.extract! tenant, :id, :tenant_category_id, :company_name, :trading_name, :registration_number, :bp_number, :vat_number, :address_1, :address_2, :location, :city, :country, :website, :info_email, :sales_email, :mobile_1, :mobile_2, :phone_1, :phone_2, :fax_number, :active, :created_at, :updated_at
json.url tenant_url(tenant, format: :json)

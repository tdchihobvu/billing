require "application_system_test_case"

class TenantsTest < ApplicationSystemTestCase
  setup do
    @tenant = tenants(:one)
  end

  test "visiting the index" do
    visit tenants_url
    assert_selector "h1", text: "Tenants"
  end

  test "should create tenant" do
    visit tenants_url
    click_on "New tenant"

    check "Active" if @tenant.active
    fill_in "Address 1", with: @tenant.address_1
    fill_in "Address 2", with: @tenant.address_2
    fill_in "Bp number", with: @tenant.bp_number
    fill_in "City", with: @tenant.city
    fill_in "Company name", with: @tenant.company_name
    fill_in "Country", with: @tenant.country
    fill_in "Fax number", with: @tenant.fax_number
    fill_in "Info email", with: @tenant.info_email
    fill_in "Location", with: @tenant.location
    fill_in "Mobile 1", with: @tenant.mobile_1
    fill_in "Mobile 2", with: @tenant.mobile_2
    fill_in "Phone 1", with: @tenant.phone_1
    fill_in "Phone 2", with: @tenant.phone_2
    fill_in "Registration number", with: @tenant.registration_number
    fill_in "Sales email", with: @tenant.sales_email
    fill_in "Tenant category", with: @tenant.tenant_category_id
    fill_in "Trading name", with: @tenant.trading_name
    fill_in "Vat number", with: @tenant.vat_number
    fill_in "Website", with: @tenant.website
    click_on "Create Tenant"

    assert_text "Tenant was successfully created"
    click_on "Back"
  end

  test "should update Tenant" do
    visit tenant_url(@tenant)
    click_on "Edit this tenant", match: :first

    check "Active" if @tenant.active
    fill_in "Address 1", with: @tenant.address_1
    fill_in "Address 2", with: @tenant.address_2
    fill_in "Bp number", with: @tenant.bp_number
    fill_in "City", with: @tenant.city
    fill_in "Company name", with: @tenant.company_name
    fill_in "Country", with: @tenant.country
    fill_in "Fax number", with: @tenant.fax_number
    fill_in "Info email", with: @tenant.info_email
    fill_in "Location", with: @tenant.location
    fill_in "Mobile 1", with: @tenant.mobile_1
    fill_in "Mobile 2", with: @tenant.mobile_2
    fill_in "Phone 1", with: @tenant.phone_1
    fill_in "Phone 2", with: @tenant.phone_2
    fill_in "Registration number", with: @tenant.registration_number
    fill_in "Sales email", with: @tenant.sales_email
    fill_in "Tenant category", with: @tenant.tenant_category_id
    fill_in "Trading name", with: @tenant.trading_name
    fill_in "Vat number", with: @tenant.vat_number
    fill_in "Website", with: @tenant.website
    click_on "Update Tenant"

    assert_text "Tenant was successfully updated"
    click_on "Back"
  end

  test "should destroy Tenant" do
    visit tenant_url(@tenant)
    click_on "Destroy this tenant", match: :first

    assert_text "Tenant was successfully destroyed"
  end
end

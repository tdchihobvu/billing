require "test_helper"

class TenantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = tenants(:one)
  end

  test "should get index" do
    get tenants_url
    assert_response :success
  end

  test "should get new" do
    get new_tenant_url
    assert_response :success
  end

  test "should create tenant" do
    assert_difference("Tenant.count") do
      post tenants_url, params: { tenant: { active: @tenant.active, address_1: @tenant.address_1, address_2: @tenant.address_2, bp_number: @tenant.bp_number, city: @tenant.city, company_name: @tenant.company_name, country: @tenant.country, fax_number: @tenant.fax_number, info_email: @tenant.info_email, location: @tenant.location, mobile_1: @tenant.mobile_1, mobile_2: @tenant.mobile_2, phone_1: @tenant.phone_1, phone_2: @tenant.phone_2, registration_number: @tenant.registration_number, sales_email: @tenant.sales_email, tenant_category_id: @tenant.tenant_category_id, trading_name: @tenant.trading_name, vat_number: @tenant.vat_number, website: @tenant.website } }
    end

    assert_redirected_to tenant_url(Tenant.last)
  end

  test "should show tenant" do
    get tenant_url(@tenant)
    assert_response :success
  end

  test "should get edit" do
    get edit_tenant_url(@tenant)
    assert_response :success
  end

  test "should update tenant" do
    patch tenant_url(@tenant), params: { tenant: { active: @tenant.active, address_1: @tenant.address_1, address_2: @tenant.address_2, bp_number: @tenant.bp_number, city: @tenant.city, company_name: @tenant.company_name, country: @tenant.country, fax_number: @tenant.fax_number, info_email: @tenant.info_email, location: @tenant.location, mobile_1: @tenant.mobile_1, mobile_2: @tenant.mobile_2, phone_1: @tenant.phone_1, phone_2: @tenant.phone_2, registration_number: @tenant.registration_number, sales_email: @tenant.sales_email, tenant_category_id: @tenant.tenant_category_id, trading_name: @tenant.trading_name, vat_number: @tenant.vat_number, website: @tenant.website } }
    assert_redirected_to tenant_url(@tenant)
  end

  test "should destroy tenant" do
    assert_difference("Tenant.count", -1) do
      delete tenant_url(@tenant)
    end

    assert_redirected_to tenants_url
  end
end

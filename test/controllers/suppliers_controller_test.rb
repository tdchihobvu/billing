require "test_helper"

class SuppliersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @supplier = suppliers(:one)
  end

  test "should get index" do
    get suppliers_url
    assert_response :success
  end

  test "should get new" do
    get new_supplier_url
    assert_response :success
  end

  test "should create supplier" do
    assert_difference("Supplier.count") do
      post suppliers_url, params: { supplier: { active: @supplier.active, address_1: @supplier.address_1, address_2: @supplier.address_2, bp_number: @supplier.bp_number, contact_mobile: @supplier.contact_mobile, contact_person: @supplier.contact_person, country: @supplier.country, email: @supplier.email, location: @supplier.location, name: @supplier.name, phone: @supplier.phone, vat_number: @supplier.vat_number } }
    end

    assert_redirected_to supplier_url(Supplier.last)
  end

  test "should show supplier" do
    get supplier_url(@supplier)
    assert_response :success
  end

  test "should get edit" do
    get edit_supplier_url(@supplier)
    assert_response :success
  end

  test "should update supplier" do
    patch supplier_url(@supplier), params: { supplier: { active: @supplier.active, address_1: @supplier.address_1, address_2: @supplier.address_2, bp_number: @supplier.bp_number, contact_mobile: @supplier.contact_mobile, contact_person: @supplier.contact_person, country: @supplier.country, email: @supplier.email, location: @supplier.location, name: @supplier.name, phone: @supplier.phone, vat_number: @supplier.vat_number } }
    assert_redirected_to supplier_url(@supplier)
  end

  test "should destroy supplier" do
    assert_difference("Supplier.count", -1) do
      delete supplier_url(@supplier)
    end

    assert_redirected_to suppliers_url
  end
end

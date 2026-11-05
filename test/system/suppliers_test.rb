require "application_system_test_case"

class SuppliersTest < ApplicationSystemTestCase
  setup do
    @supplier = suppliers(:one)
  end

  test "visiting the index" do
    visit suppliers_url
    assert_selector "h1", text: "Suppliers"
  end

  test "should create supplier" do
    visit suppliers_url
    click_on "New supplier"

    check "Active" if @supplier.active
    fill_in "Address 1", with: @supplier.address_1
    fill_in "Address 2", with: @supplier.address_2
    fill_in "Bp number", with: @supplier.bp_number
    fill_in "Contact mobile", with: @supplier.contact_mobile
    fill_in "Contact person", with: @supplier.contact_person
    fill_in "Country", with: @supplier.country
    fill_in "Email", with: @supplier.email
    fill_in "Location", with: @supplier.location
    fill_in "Name", with: @supplier.name
    fill_in "Phone", with: @supplier.phone
    fill_in "Vat number", with: @supplier.vat_number
    click_on "Create Supplier"

    assert_text "Supplier was successfully created"
    click_on "Back"
  end

  test "should update Supplier" do
    visit supplier_url(@supplier)
    click_on "Edit this supplier", match: :first

    check "Active" if @supplier.active
    fill_in "Address 1", with: @supplier.address_1
    fill_in "Address 2", with: @supplier.address_2
    fill_in "Bp number", with: @supplier.bp_number
    fill_in "Contact mobile", with: @supplier.contact_mobile
    fill_in "Contact person", with: @supplier.contact_person
    fill_in "Country", with: @supplier.country
    fill_in "Email", with: @supplier.email
    fill_in "Location", with: @supplier.location
    fill_in "Name", with: @supplier.name
    fill_in "Phone", with: @supplier.phone
    fill_in "Vat number", with: @supplier.vat_number
    click_on "Update Supplier"

    assert_text "Supplier was successfully updated"
    click_on "Back"
  end

  test "should destroy Supplier" do
    visit supplier_url(@supplier)
    click_on "Destroy this supplier", match: :first

    assert_text "Supplier was successfully destroyed"
  end
end

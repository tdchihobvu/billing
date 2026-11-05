require "application_system_test_case"

class VatTypesTest < ApplicationSystemTestCase
  setup do
    @vat_type = vat_types(:one)
  end

  test "visiting the index" do
    visit vat_types_url
    assert_selector "h1", text: "Vat types"
  end

  test "should create vat type" do
    visit vat_types_url
    click_on "New vat type"

    fill_in "Name", with: @vat_type.name
    fill_in "Rate", with: @vat_type.rate
    click_on "Create Vat type"

    assert_text "Vat type was successfully created"
    click_on "Back"
  end

  test "should update Vat type" do
    visit vat_type_url(@vat_type)
    click_on "Edit this vat type", match: :first

    fill_in "Name", with: @vat_type.name
    fill_in "Rate", with: @vat_type.rate
    click_on "Update Vat type"

    assert_text "Vat type was successfully updated"
    click_on "Back"
  end

  test "should destroy Vat type" do
    visit vat_type_url(@vat_type)
    click_on "Destroy this vat type", match: :first

    assert_text "Vat type was successfully destroyed"
  end
end

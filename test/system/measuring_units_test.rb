require "application_system_test_case"

class MeasuringUnitsTest < ApplicationSystemTestCase
  setup do
    @measuring_unit = measuring_units(:one)
  end

  test "visiting the index" do
    visit measuring_units_url
    assert_selector "h1", text: "Measuring units"
  end

  test "should create measuring unit" do
    visit measuring_units_url
    click_on "New measuring unit"

    fill_in "Name", with: @measuring_unit.name
    fill_in "Symbol", with: @measuring_unit.symbol
    click_on "Create Measuring unit"

    assert_text "Measuring unit was successfully created"
    click_on "Back"
  end

  test "should update Measuring unit" do
    visit measuring_unit_url(@measuring_unit)
    click_on "Edit this measuring unit", match: :first

    fill_in "Name", with: @measuring_unit.name
    fill_in "Symbol", with: @measuring_unit.symbol
    click_on "Update Measuring unit"

    assert_text "Measuring unit was successfully updated"
    click_on "Back"
  end

  test "should destroy Measuring unit" do
    visit measuring_unit_url(@measuring_unit)
    click_on "Destroy this measuring unit", match: :first

    assert_text "Measuring unit was successfully destroyed"
  end
end

require "application_system_test_case"

class RegionalOfficesTest < ApplicationSystemTestCase
  setup do
    @regional_office = regional_offices(:one)
  end

  test "visiting the index" do
    visit regional_offices_url
    assert_selector "h1", text: "Regional offices"
  end

  test "should create regional office" do
    visit regional_offices_url
    click_on "New regional office"

    fill_in "Name", with: @regional_office.name
    fill_in "Region", with: @regional_office.region_id
    click_on "Create Regional office"

    assert_text "Regional office was successfully created"
    click_on "Back"
  end

  test "should update Regional office" do
    visit regional_office_url(@regional_office)
    click_on "Edit this regional office", match: :first

    fill_in "Name", with: @regional_office.name
    fill_in "Region", with: @regional_office.region_id
    click_on "Update Regional office"

    assert_text "Regional office was successfully updated"
    click_on "Back"
  end

  test "should destroy Regional office" do
    visit regional_office_url(@regional_office)
    click_on "Destroy this regional office", match: :first

    assert_text "Regional office was successfully destroyed"
  end
end

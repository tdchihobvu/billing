require "application_system_test_case"

class LicenseOptionsTest < ApplicationSystemTestCase
  setup do
    @license_option = license_options(:one)
  end

  test "visiting the index" do
    visit license_options_url
    assert_selector "h1", text: "License options"
  end

  test "should create license option" do
    visit license_options_url
    click_on "New license option"

    check "Active" if @license_option.active
    fill_in "Months", with: @license_option.months
    fill_in "Name", with: @license_option.name
    click_on "Create License option"

    assert_text "License option was successfully created"
    click_on "Back"
  end

  test "should update License option" do
    visit license_option_url(@license_option)
    click_on "Edit this license option", match: :first

    check "Active" if @license_option.active
    fill_in "Months", with: @license_option.months
    fill_in "Name", with: @license_option.name
    click_on "Update License option"

    assert_text "License option was successfully updated"
    click_on "Back"
  end

  test "should destroy License option" do
    visit license_option_url(@license_option)
    click_on "Destroy this license option", match: :first

    assert_text "License option was successfully destroyed"
  end
end

require "application_system_test_case"

class LicensesTest < ApplicationSystemTestCase
  setup do
    @license = licenses(:one)
  end

  test "visiting the index" do
    visit licenses_url
    assert_selector "h1", text: "Licenses"
  end

  test "should create license" do
    visit licenses_url
    click_on "New license"

    check "Active" if @license.active
    check "Auto renewal" if @license.auto_renewal
    fill_in "Client", with: @license.client_id
    fill_in "Expiry date", with: @license.expiry_date
    fill_in "License category", with: @license.license_category_id
    fill_in "License option", with: @license.license_option_id
    fill_in "Printed", with: @license.printed
    fill_in "Renewal date", with: @license.renewal_date
    click_on "Create License"

    assert_text "License was successfully created"
    click_on "Back"
  end

  test "should update License" do
    visit license_url(@license)
    click_on "Edit this license", match: :first

    check "Active" if @license.active
    check "Auto renewal" if @license.auto_renewal
    fill_in "Client", with: @license.client_id
    fill_in "Expiry date", with: @license.expiry_date
    fill_in "License category", with: @license.license_category_id
    fill_in "License option", with: @license.license_option_id
    fill_in "Printed", with: @license.printed
    fill_in "Renewal date", with: @license.renewal_date
    click_on "Update License"

    assert_text "License was successfully updated"
    click_on "Back"
  end

  test "should destroy License" do
    visit license_url(@license)
    click_on "Destroy this license", match: :first

    assert_text "License was successfully destroyed"
  end
end

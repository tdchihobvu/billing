require "application_system_test_case"

class TarrifsTest < ApplicationSystemTestCase
  setup do
    @tarrif = tarrifs(:one)
  end

  test "visiting the index" do
    visit tarrifs_url
    assert_selector "h1", text: "Tarrifs"
  end

  test "should create tarrif" do
    visit tarrifs_url
    click_on "New tarrif"

    fill_in "Amount", with: @tarrif.amount
    fill_in "Industry", with: @tarrif.industry_id
    fill_in "Name", with: @tarrif.name
    click_on "Create Tarrif"

    assert_text "Tarrif was successfully created"
    click_on "Back"
  end

  test "should update Tarrif" do
    visit tarrif_url(@tarrif)
    click_on "Edit this tarrif", match: :first

    fill_in "Amount", with: @tarrif.amount
    fill_in "Industry", with: @tarrif.industry_id
    fill_in "Name", with: @tarrif.name
    click_on "Update Tarrif"

    assert_text "Tarrif was successfully updated"
    click_on "Back"
  end

  test "should destroy Tarrif" do
    visit tarrif_url(@tarrif)
    click_on "Destroy this tarrif", match: :first

    assert_text "Tarrif was successfully destroyed"
  end
end

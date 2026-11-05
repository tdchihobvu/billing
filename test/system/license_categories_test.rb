require "application_system_test_case"

class LicenseCategoriesTest < ApplicationSystemTestCase
  setup do
    @license_category = license_categories(:one)
  end

  test "visiting the index" do
    visit license_categories_url
    assert_selector "h1", text: "License categories"
  end

  test "should create license category" do
    visit license_categories_url
    click_on "New license category"

    fill_in "Description", with: @license_category.description
    fill_in "Name", with: @license_category.name
    click_on "Create License category"

    assert_text "License category was successfully created"
    click_on "Back"
  end

  test "should update License category" do
    visit license_category_url(@license_category)
    click_on "Edit this license category", match: :first

    fill_in "Description", with: @license_category.description
    fill_in "Name", with: @license_category.name
    click_on "Update License category"

    assert_text "License category was successfully updated"
    click_on "Back"
  end

  test "should destroy License category" do
    visit license_category_url(@license_category)
    click_on "Destroy this license category", match: :first

    assert_text "License category was successfully destroyed"
  end
end

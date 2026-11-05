require "application_system_test_case"

class SettingCategoriesTest < ApplicationSystemTestCase
  setup do
    @setting_category = setting_categories(:one)
  end

  test "visiting the index" do
    visit setting_categories_url
    assert_selector "h1", text: "Setting categories"
  end

  test "should create setting category" do
    visit setting_categories_url
    click_on "New setting category"

    fill_in "Name", with: @setting_category.name
    click_on "Create Setting category"

    assert_text "Setting category was successfully created"
    click_on "Back"
  end

  test "should update Setting category" do
    visit setting_category_url(@setting_category)
    click_on "Edit this setting category", match: :first

    fill_in "Name", with: @setting_category.name
    click_on "Update Setting category"

    assert_text "Setting category was successfully updated"
    click_on "Back"
  end

  test "should destroy Setting category" do
    visit setting_category_url(@setting_category)
    click_on "Destroy this setting category", match: :first

    assert_text "Setting category was successfully destroyed"
  end
end

require "test_helper"

class SettingCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @setting_category = setting_categories(:one)
  end

  test "should get index" do
    get setting_categories_url
    assert_response :success
  end

  test "should get new" do
    get new_setting_category_url
    assert_response :success
  end

  test "should create setting_category" do
    assert_difference("SettingCategory.count") do
      post setting_categories_url, params: { setting_category: { name: @setting_category.name } }
    end

    assert_redirected_to setting_category_url(SettingCategory.last)
  end

  test "should show setting_category" do
    get setting_category_url(@setting_category)
    assert_response :success
  end

  test "should get edit" do
    get edit_setting_category_url(@setting_category)
    assert_response :success
  end

  test "should update setting_category" do
    patch setting_category_url(@setting_category), params: { setting_category: { name: @setting_category.name } }
    assert_redirected_to setting_category_url(@setting_category)
  end

  test "should destroy setting_category" do
    assert_difference("SettingCategory.count", -1) do
      delete setting_category_url(@setting_category)
    end

    assert_redirected_to setting_categories_url
  end
end

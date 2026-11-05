require "test_helper"

class LicenseCategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @license_category = license_categories(:one)
  end

  test "should get index" do
    get license_categories_url
    assert_response :success
  end

  test "should get new" do
    get new_license_category_url
    assert_response :success
  end

  test "should create license_category" do
    assert_difference("LicenseCategory.count") do
      post license_categories_url, params: { license_category: { description: @license_category.description, name: @license_category.name } }
    end

    assert_redirected_to license_category_url(LicenseCategory.last)
  end

  test "should show license_category" do
    get license_category_url(@license_category)
    assert_response :success
  end

  test "should get edit" do
    get edit_license_category_url(@license_category)
    assert_response :success
  end

  test "should update license_category" do
    patch license_category_url(@license_category), params: { license_category: { description: @license_category.description, name: @license_category.name } }
    assert_redirected_to license_category_url(@license_category)
  end

  test "should destroy license_category" do
    assert_difference("LicenseCategory.count", -1) do
      delete license_category_url(@license_category)
    end

    assert_redirected_to license_categories_url
  end
end

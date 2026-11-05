require "test_helper"

class LicenseOptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @license_option = license_options(:one)
  end

  test "should get index" do
    get license_options_url
    assert_response :success
  end

  test "should get new" do
    get new_license_option_url
    assert_response :success
  end

  test "should create license_option" do
    assert_difference("LicenseOption.count") do
      post license_options_url, params: { license_option: { active: @license_option.active, months: @license_option.months, name: @license_option.name } }
    end

    assert_redirected_to license_option_url(LicenseOption.last)
  end

  test "should show license_option" do
    get license_option_url(@license_option)
    assert_response :success
  end

  test "should get edit" do
    get edit_license_option_url(@license_option)
    assert_response :success
  end

  test "should update license_option" do
    patch license_option_url(@license_option), params: { license_option: { active: @license_option.active, months: @license_option.months, name: @license_option.name } }
    assert_redirected_to license_option_url(@license_option)
  end

  test "should destroy license_option" do
    assert_difference("LicenseOption.count", -1) do
      delete license_option_url(@license_option)
    end

    assert_redirected_to license_options_url
  end
end

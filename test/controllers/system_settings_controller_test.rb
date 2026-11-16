require "test_helper"

class SystemSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get system_settings_url
    assert_response :success
  end
end

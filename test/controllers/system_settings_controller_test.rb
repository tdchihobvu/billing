require "test_helper"

class SystemSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get system_settings_index_url
    assert_response :success
  end
end

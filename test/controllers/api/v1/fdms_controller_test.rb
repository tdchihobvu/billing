require "test_helper"

class Api::V1::FdmsControllerTest < ActionDispatch::IntegrationTest
  test "should get register_device" do
    get api_v1_fdms_register_device_url
    assert_response :success
  end
end

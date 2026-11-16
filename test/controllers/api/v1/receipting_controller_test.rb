require "test_helper"

class Api::V1::ReceiptingControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get new_api_v1_receipting_url
    assert_response :success
  end
end

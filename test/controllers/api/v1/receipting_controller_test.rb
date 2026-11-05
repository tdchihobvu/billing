require "test_helper"

class Api::V1::ReceiptingControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get api_v1_receipting_new_url
    assert_response :success
  end
end

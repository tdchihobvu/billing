require "test_helper"

# Regression tests for the issues found in the November 2026 audit.
class AuditFixesTest < ActionDispatch::IntegrationTest
  test "another company's bank account cannot be opened by changing the id" do
    get bank_url(banks(:two))

    assert_not_equal 200, response.status
  end

  test "a shift's details page lists the shift" do
    get shift_receipts_url(shift_id: shifts(:one).id)

    assert_response :success
    assert_includes response.body, "Shift #{shifts(:one).shift_id}"
  end

  test "another company's shift is not shown" do
    get shift_receipts_url(shift_id: shifts(:two).id)

    assert_redirected_to shifts_receipts_url
  end

  test "an empty password change asks for a password instead of failing or claiming success" do
    patch password_change_url

    assert_response :unprocessable_entity
    assert_includes response.body, "enter a new password"
  end

  test "an inspector is not shown buttons their role cannot use" do
    sign_out users(:one)
    sign_in users(:two)
    get clients_url

    assert_response :success
    assert_not_includes response.body, "Industries and tariffs"
  end

  test "a phone upload the office refuses is logged in System health with the details the phone sent" do
    device = devices(:one)
    device.update_columns(active: true, access_token: "token-1", user_id: users(:one).id, tenant_id: tenants(:one).id)
    headers = { "TerminalId" => device.terminal_id, "accessToken" => "token-1" }

    assert_difference -> { SystemEvent.where(kind: "mobile_upload").count }, 1 do
      post new_branch_api_v1_billing_index_url, params: { clientName: "Nobody Here", name: "Town", address: "1 Main" },
                                                headers: headers, as: :json
    end

    event = SystemEvent.where(kind: "mobile_upload").last
    assert_match "branch for Nobody Here", event.title
    assert_match "Reason:", event.details
    assert_match "Client: Nobody Here", event.details
    assert_match "Device:", event.details
  end

  test "search treats % and _ as plain characters" do
    assert_equal ["a_b"], TextSearch.words("a_b")
    assert_equal ["100%"], TextSearch.words(" 100% ")
  end
end

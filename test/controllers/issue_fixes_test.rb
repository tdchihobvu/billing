require "test_helper"
require "minitest/mock"

class IssueFixesTest < ActionDispatch::IntegrationTest
  XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  test "overdue lists only unpaid invoices past their due date" do
    overdue, recent = invoices(:one), invoices(:two)
    overdue.update_columns(deleted: false, paid: false, is_proforma: false, invoice_total: 100, amount_paid: 0, due_date: Date.current - 3)
    recent.update_columns(invoice_date: Date.current - 1, client_id: overdue.client_id, tenant_id: overdue.tenant_id, deleted: false, paid: false, is_proforma: false, invoice_total: 100, amount_paid: 0, due_date: Date.current + 3)
    get overdue_invoices_reports_url

    assert_response :success
    assert_includes response.body, overdue.invoice_number
    assert_select "table tbody tr", 1
  end

  test "an invoice with no due date uses its validity period" do
    invoice = invoices(:one)
    invoice.update_columns(deleted: false, paid: false, is_proforma: false, invoice_total: 100, amount_paid: 0, due_date: nil, invoice_date: Date.current - 40)
    get overdue_invoices_reports_url

    assert_select "table tbody tr", 1
    get overdue_invoices_reports_url(format: :xlsx)
    assert_response :success
  end

  test "inspector report downloads as excel" do
    get inspector_report_reports_url
    assert_response :success

    get inspector_report_reports_url(format: :xlsx), params: { from: "2024-01-01", to: Date.current.to_s }
    assert_response :success
    assert_equal XLSX, response.media_type
  end

  test "expiring licences report filters by date and downloads" do
    license = licenses(:one)
    license.update_columns(expiry_date: Date.current + 5)
    invoices(:one).update_columns(deleted: false)
    get upcoming_renewals_reports_url, params: { from: Date.current.to_s, to: (Date.current + 10).to_s }
    assert_response :success

    get upcoming_renewals_reports_url(format: :xlsx), params: { from: Date.current.to_s, to: (Date.current + 10).to_s }
    assert_response :success
    assert_equal XLSX, response.media_type
  end

  test "export by inspector downloads" do
    get sales_by_user_reports_url(format: :xlsx)

    assert_response :success
    assert_equal XLSX, response.media_type
  end

  test "unexpected errors become a clear message in production" do
    Rails.stub :env, ActiveSupport::EnvironmentInquirer.new("production") do
      Invoice.stub :filter, ->(*) { raise "boom" } do
        get sales_reports_url, headers: { "HTTP_REFERER" => reports_url }
      end
    end

    assert_response :see_other
    assert_match(/could not be completed/, flash[:alert])
  end

  test "users are grouped by role" do
    get user_management_index_url

    assert_response :success
    assert_select "h2", /Superadmin/
  end

  test "admin reset forces a password change" do
    target = users(:two)
    target.update_column(:tenant_id, users(:one).tenant_id)
    get reset_user_management_index_url(id: target)

    assert target.reload.must_change_password?
    assert_match(/Temporary password/, flash[:notice])
    refute target.using_default_password?
  end

  test "a user with a temporary password must change it first" do
    users(:one).update_column(:must_change_password, true)
    get clients_url
    assert_redirected_to edit_password_change_url

    patch password_change_url, params: { user: { password: "a-Better-pass1", password_confirmation: "a-Better-pass1" } }
    assert_redirected_to root_url
    assert_not users(:one).reload.must_change_password?
  end

  test "the default password pattern is refused as a new password" do
    user = users(:one)
    user.update_column(:must_change_password, true)
    default = "#{user.username.downcase}!@#"
    patch password_change_url, params: { user: { password: default, password_confirmation: default } }

    assert_response :unprocessable_entity
  end

  test "a failed reset email shows a clear message" do
    sign_out users(:one)
    failure = ->(*) { raise ArgumentError, "SMTP-AUTH requested but missing secret phrase" }

    Devise::Mailer.stub :reset_password_instructions, failure do
      post user_password_url, params: { user: { email: users(:one).email } }
    end

    assert_redirected_to new_user_password_url
    follow_redirect!
    assert_select "p.alert", /could not send the reset email/
  end

  test "forgot password sends instructions" do
    sign_out users(:one)
    assert_emails 1 do
      post user_password_url, params: { user: { email: users(:one).email } }
    end
  end

  test "a named branch prints that name" do
    branch = Branch.new(display_name: "Avondale branch")

    assert_equal "Avondale branch", branch.branch_name
  end
end

class IssueFixesApiTest < ActionDispatch::IntegrationTest
  setup do
    @device = devices(:one)
    @device.update_columns(active: true, access_token: "token-1", user_id: users(:one).id, tenant_id: tenants(:one).id)
    @headers = { "TerminalId" => @device.terminal_id, "accessToken" => "token-1" }
    @client = clients(:one)
  end

  test "website receipts appear in the device report" do
    receipt = receipts(:one)
    receipt.update_columns(user_id: @device.user_id, deleted: false, invoice_id: invoices(:one).id, invoice_reference: nil, transaction_source: "BaseApplication")
    get user_receipts_api_v1_billing_index_url, headers: @headers

    assert_response :success
    assert_includes response.body, receipt.reference_number
  end

  test "open invoices include another inspector's part-paid invoice" do
    invoice = invoices(:one)
    invoice.update_columns(user_id: users(:two).id, deleted: false, is_proforma: false, invoice_total: 100, amount_paid: 40, client_id: @client.id)
    get open_invoices_api_v1_billing_index_url, params: { client_name: @client.name }, headers: @headers

    assert_response :success
    assert_includes response.body, invoice.invoice_number
  end

  test "licence search reports validity" do
    license = licenses(:one)
    license.update_columns(client_id: @client.id, active: true, paid: true, expiry_date: Date.current + 10)
    invoices(:one).update_columns(deleted: false)
    get license_status_api_v1_billing_index_url, params: { search: @client.name }, headers: @headers

    assert_response :success
    assert_equal "Valid", response.parsed_body.first["license_status"]
  end

  test "company details include bank accounts" do
    banks(:one).update_columns(tenant_id: tenants(:one).id, active: true)
    get company_details_api_v1_billing_index_url, headers: @headers

    assert_response :success
    assert response.parsed_body["banks"].any?
  end

  test "a branch sent the way the app sends it is saved with its name" do
    LicenseOption.first.update_column(:name, "Annually")
    assert_difference("Branch.count") do
      post new_branch_api_v1_billing_index_url, params: { clientName: @client.name, name: "Town branch", address: "1 Main", location: "CBD", city: "Harare" }, headers: @headers, as: :json
    end

    assert_response :created
    branch = Branch.order(:created_at).last
    assert_equal "1 Main", branch.address_1
    assert_equal "Town branch", branch.branch_name
  end

  test "sending the same branch twice reports that it already exists" do
    LicenseOption.first.update_column(:name, "Annually")
    body = { clientName: @client.name, name: "Town", address: "1 Main", location: "CBD", city: "Harare" }
    post new_branch_api_v1_billing_index_url, params: body, headers: @headers, as: :json
    post new_branch_api_v1_billing_index_url, params: body, headers: @headers, as: :json

    assert_response :conflict
    assert_match(/already exist/, response.parsed_body["message"])
  end
end

require "test_helper"

class LicensesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @license = licenses(:one)
  end

  test "should get index" do
    get licenses_url
    assert_response :success
  end

  test "should get new" do
    get new_license_url
    assert_response :success
  end

  test "should create license" do
    assert_difference("License.count") do
      post licenses_url, params: { license: fresh_attributes(@license) }
    end

    assert_redirected_to license_url(License.last)
  end

  test "should show license" do
    get license_url(@license)
    assert_response :success
  end

  test "should get edit" do
    get edit_license_url(@license)
    assert_response :success
  end

  test "should update license" do
    patch license_url(@license), params: { license: { active: @license.active, auto_renewal: @license.auto_renewal, client_id: @license.client_id, expiry_date: @license.expiry_date, license_category_id: @license.license_category_id, license_option_id: @license.license_option_id, printed: @license.printed, renewal_date: @license.renewal_date } }
    assert_redirected_to license_url(@license)
  end

  test "should destroy license" do
    record = unreferenced_copy(@license)

    assert_difference("License.count", -1) do
      delete license_url(record)
    end

    assert_redirected_to licenses_url
  end

  test "should page licenses as json" do
    licenses(:one).update_columns(active: true, expiry_date: Date.today + 30)
    invoices(:one).update_column(:deleted, false)
    get licenses_url(format: :json), params: { draw: 1, order: { "0" => { column: 1, dir: "asc" } } }

    assert_response :success
    assert_equal 6, response.parsed_body["data"].first.size
  end

  test "should mark a settled license paid when listing" do
    license = licenses(:one)
    license.update_columns(active: true, paid: false, expiry_date: Date.today + 30)
    license.invoice.update_columns(invoice_total: 100, amount_paid: 100)
    get licenses_url

    assert_response :success
    assert license.reload.paid
  end
end

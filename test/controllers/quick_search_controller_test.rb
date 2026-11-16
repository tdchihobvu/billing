require "test_helper"

class QuickSearchControllerTest < ActionDispatch::IntegrationTest
  test "should find a client regardless of case" do
    client = clients(:one)
    get quick_search_url, params: { q: client.name.swapcase }

    assert_response :success
    assert_equal [client_path(client)], response.parsed_body["clients"].map { |row| row["url"] }
  end

  test "should find an invoice by number" do
    invoice = invoices(:one)
    invoice.update_columns(invoice_number: "INV-7788", deleted: false)
    get quick_search_url, params: { q: "inv-77" }

    assert_equal [invoice_path(invoice)], response.parsed_body["invoices"].map { |row| row["url"] }
  end

  test "should not search on a single character" do
    get quick_search_url, params: { q: "a" }

    assert_equal({ "clients" => [], "invoices" => [] }, response.parsed_body)
  end

  test "should treat wildcards as plain text" do
    get quick_search_url, params: { q: "%%" }

    assert_empty response.parsed_body["clients"]
  end

  test "should require sign in" do
    sign_out users(:one)
    get quick_search_url

    assert_redirected_to new_user_session_url
  end
end

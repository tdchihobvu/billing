require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client = clients(:one)
  end

  test "should get index" do
    get clients_url
    assert_response :success
  end

  test "should get new" do
    get new_client_url
    assert_response :success
  end

  test "should create client" do
    assert_difference("Client.count") do
      post clients_url, params: { client: fresh_attributes(@client) }
    end

    assert_redirected_to client_url(Client.last)
  end

  test "should show client" do
    get client_url(@client)
    assert_response :success
  end

  test "should get edit" do
    get edit_client_url(@client)
    assert_response :success
  end

  test "should update client" do
    patch client_url(@client), params: { client: { active: @client.active, address_1: @client.address_1, address_2: @client.address_2, bp_number: @client.bp_number, city: @client.city, client_type_id: @client.client_type_id, country: @client.country, cp_email: @client.cp_email, cp_mobile: @client.cp_mobile, cp_name: @client.cp_name, email: @client.email, industry_id: @client.industry_id, location: @client.location, mobile: @client.mobile, name: @client.name, phone: @client.phone, trading_name: @client.trading_name, vat_number: @client.vat_number, website: @client.website } }
    assert_redirected_to client_url(@client)
  end

  test "should soft delete client" do
    assert_no_difference("Client.count") do
      delete client_url(@client)
    end

    assert_equal false, @client.reload.active
    assert_redirected_to clients_url
  end

  test "should page clients as json" do
    get clients_url(format: :json), params: { draw: 3, start: 0, length: 1 }

    assert_response :success
    body = response.parsed_body
    assert_equal 3, body["draw"]
    assert_equal 1, body["recordsTotal"]
    assert_equal 1, body["data"].size
    assert_equal 7, body["data"].first.size
  end

  test "should search every client regardless of case" do
    target = clients(:one)
    get clients_url(format: :json), params: { draw: 1, search: { value: target.name.swapcase } }

    assert_response :success
    assert_equal 1, response.parsed_body["recordsFiltered"]
  end

  test "should escape client values in json" do
    clients(:one).update_column(:name, "<script>alert(1)</script>")
    get clients_url(format: :json), params: { draw: 1 }

    assert_includes response.body, "\\u0026lt;script"
    refute_includes response.body, "<script>"
  end

  test "should ignore unsafe sort input" do
    get clients_url(format: :json), params: { draw: 1, order: { "0" => { column: "2; DROP TABLE clients", dir: "desc; DROP TABLE clients" } } }

    assert_response :success
    assert Client.exists?
  end
end

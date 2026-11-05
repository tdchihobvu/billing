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
      post clients_url, params: { client: { active: @client.active, address_1: @client.address_1, address_2: @client.address_2, bp_number: @client.bp_number, city: @client.city, client_type_id: @client.client_type_id, country: @client.country, cp_email: @client.cp_email, cp_mobile: @client.cp_mobile, cp_name: @client.cp_name, email: @client.email, industry_id: @client.industry_id, location: @client.location, mobile: @client.mobile, name: @client.name, phone: @client.phone, trading_name: @client.trading_name, vat_number: @client.vat_number, website: @client.website } }
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

  test "should destroy client" do
    assert_difference("Client.count", -1) do
      delete client_url(@client)
    end

    assert_redirected_to clients_url
  end
end

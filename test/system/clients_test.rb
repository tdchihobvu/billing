require "application_system_test_case"

class ClientsTest < ApplicationSystemTestCase
  setup do
    @client = clients(:one)
  end

  test "visiting the index" do
    visit clients_url
    assert_selector "h1", text: "Clients"
  end

  test "should create client" do
    visit clients_url
    click_on "New client"

    check "Active" if @client.active
    fill_in "Address 1", with: @client.address_1
    fill_in "Address 2", with: @client.address_2
    fill_in "Bp number", with: @client.bp_number
    fill_in "City", with: @client.city
    fill_in "Client type", with: @client.client_type_id
    fill_in "Country", with: @client.country
    fill_in "Cp email", with: @client.cp_email
    fill_in "Cp mobile", with: @client.cp_mobile
    fill_in "Cp name", with: @client.cp_name
    fill_in "Email", with: @client.email
    fill_in "Industry", with: @client.industry_id
    fill_in "Location", with: @client.location
    fill_in "Mobile", with: @client.mobile
    fill_in "Name", with: @client.name
    fill_in "Phone", with: @client.phone
    fill_in "Trading name", with: @client.trading_name
    fill_in "Vat number", with: @client.vat_number
    fill_in "Website", with: @client.website
    click_on "Create Client"

    assert_text "Client was successfully created"
    click_on "Back"
  end

  test "should update Client" do
    visit client_url(@client)
    click_on "Edit this client", match: :first

    check "Active" if @client.active
    fill_in "Address 1", with: @client.address_1
    fill_in "Address 2", with: @client.address_2
    fill_in "Bp number", with: @client.bp_number
    fill_in "City", with: @client.city
    fill_in "Client type", with: @client.client_type_id
    fill_in "Country", with: @client.country
    fill_in "Cp email", with: @client.cp_email
    fill_in "Cp mobile", with: @client.cp_mobile
    fill_in "Cp name", with: @client.cp_name
    fill_in "Email", with: @client.email
    fill_in "Industry", with: @client.industry_id
    fill_in "Location", with: @client.location
    fill_in "Mobile", with: @client.mobile
    fill_in "Name", with: @client.name
    fill_in "Phone", with: @client.phone
    fill_in "Trading name", with: @client.trading_name
    fill_in "Vat number", with: @client.vat_number
    fill_in "Website", with: @client.website
    click_on "Update Client"

    assert_text "Client was successfully updated"
    click_on "Back"
  end

  test "should destroy Client" do
    visit client_url(@client)
    click_on "Destroy this client", match: :first

    assert_text "Client was successfully destroyed"
  end
end

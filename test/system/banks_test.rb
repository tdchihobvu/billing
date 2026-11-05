require "application_system_test_case"

class BanksTest < ApplicationSystemTestCase
  setup do
    @bank = banks(:one)
  end

  test "visiting the index" do
    visit banks_url
    assert_selector "h1", text: "Banks"
  end

  test "should create bank" do
    visit banks_url
    click_on "New bank"

    fill_in "Account name", with: @bank.account_name
    fill_in "Account number", with: @bank.account_number
    check "Active" if @bank.active
    fill_in "Bank name", with: @bank.bank_name
    fill_in "Branch", with: @bank.branch
    fill_in "Currency", with: @bank.currency_id
    fill_in "Swift code", with: @bank.swift_code
    fill_in "Tenant", with: @bank.tenant_id
    click_on "Create Bank"

    assert_text "Bank was successfully created"
    click_on "Back"
  end

  test "should update Bank" do
    visit bank_url(@bank)
    click_on "Edit this bank", match: :first

    fill_in "Account name", with: @bank.account_name
    fill_in "Account number", with: @bank.account_number
    check "Active" if @bank.active
    fill_in "Bank name", with: @bank.bank_name
    fill_in "Branch", with: @bank.branch
    fill_in "Currency", with: @bank.currency_id
    fill_in "Swift code", with: @bank.swift_code
    fill_in "Tenant", with: @bank.tenant_id
    click_on "Update Bank"

    assert_text "Bank was successfully updated"
    click_on "Back"
  end

  test "should destroy Bank" do
    visit bank_url(@bank)
    click_on "Destroy this bank", match: :first

    assert_text "Bank was successfully destroyed"
  end
end

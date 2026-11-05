require "application_system_test_case"

class QuotationsTest < ApplicationSystemTestCase
  setup do
    @quotation = quotations(:one)
  end

  test "visiting the index" do
    visit quotations_url
    assert_selector "h1", text: "Quotations"
  end

  test "should create quotation" do
    visit quotations_url
    click_on "New quotation"

    fill_in "Bank", with: @quotation.bank_id
    fill_in "Client", with: @quotation.client_id
    fill_in "Currency", with: @quotation.currency_id
    check "Deleted" if @quotation.deleted
    fill_in "Quotation date", with: @quotation.quotation_date
    fill_in "Quotation number", with: @quotation.quotation_number
    fill_in "Quotation terms", with: @quotation.quotation_terms
    click_on "Create Quotation"

    assert_text "Quotation was successfully created"
    click_on "Back"
  end

  test "should update Quotation" do
    visit quotation_url(@quotation)
    click_on "Edit this quotation", match: :first

    fill_in "Bank", with: @quotation.bank_id
    fill_in "Client", with: @quotation.client_id
    fill_in "Currency", with: @quotation.currency_id
    check "Deleted" if @quotation.deleted
    fill_in "Quotation date", with: @quotation.quotation_date
    fill_in "Quotation number", with: @quotation.quotation_number
    fill_in "Quotation terms", with: @quotation.quotation_terms
    click_on "Update Quotation"

    assert_text "Quotation was successfully updated"
    click_on "Back"
  end

  test "should destroy Quotation" do
    visit quotation_url(@quotation)
    click_on "Destroy this quotation", match: :first

    assert_text "Quotation was successfully destroyed"
  end
end

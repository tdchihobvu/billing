require "application_system_test_case"

class ReceiptsTest < ApplicationSystemTestCase
  setup do
    @receipt = receipts(:one)
  end

  test "visiting the index" do
    visit receipts_url
    assert_selector "h1", text: "Receipts"
  end

  test "should create receipt" do
    visit receipts_url
    click_on "New receipt"

    fill_in "Amount", with: @receipt.amount
    fill_in "Client", with: @receipt.client_id
    fill_in "Currency", with: @receipt.currency_id
    check "Deleted" if @receipt.deleted
    fill_in "Description", with: @receipt.description
    fill_in "Invoice", with: @receipt.invoice_id
    fill_in "Payment form", with: @receipt.payment_form_id
    fill_in "Rate", with: @receipt.rate
    fill_in "Reference number", with: @receipt.reference_number
    fill_in "Transaction date", with: @receipt.transaction_date
    fill_in "User", with: @receipt.user_id
    click_on "Create Receipt"

    assert_text "Receipt was successfully created"
    click_on "Back"
  end

  test "should update Receipt" do
    visit receipt_url(@receipt)
    click_on "Edit this receipt", match: :first

    fill_in "Amount", with: @receipt.amount
    fill_in "Client", with: @receipt.client_id
    fill_in "Currency", with: @receipt.currency_id
    check "Deleted" if @receipt.deleted
    fill_in "Description", with: @receipt.description
    fill_in "Invoice", with: @receipt.invoice_id
    fill_in "Payment form", with: @receipt.payment_form_id
    fill_in "Rate", with: @receipt.rate
    fill_in "Reference number", with: @receipt.reference_number
    fill_in "Transaction date", with: @receipt.transaction_date
    fill_in "User", with: @receipt.user_id
    click_on "Update Receipt"

    assert_text "Receipt was successfully updated"
    click_on "Back"
  end

  test "should destroy Receipt" do
    visit receipt_url(@receipt)
    click_on "Destroy this receipt", match: :first

    assert_text "Receipt was successfully destroyed"
  end
end

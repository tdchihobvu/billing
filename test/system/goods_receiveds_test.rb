require "application_system_test_case"

class GoodsReceivedsTest < ApplicationSystemTestCase
  setup do
    @goods_received = goods_receiveds(:one)
  end

  test "visiting the index" do
    visit goods_receiveds_url
    assert_selector "h1", text: "Goods receiveds"
  end

  test "should create goods received" do
    visit goods_receiveds_url
    click_on "New goods received"

    fill_in "Date received", with: @goods_received.date_received
    check "Deleted" if @goods_received.deleted
    fill_in "Ext number", with: @goods_received.ext_number
    fill_in "Grv number", with: @goods_received.grv_number
    fill_in "Supplier", with: @goods_received.supplier_id
    fill_in "User", with: @goods_received.user_id
    click_on "Create Goods received"

    assert_text "Goods received was successfully created"
    click_on "Back"
  end

  test "should update Goods received" do
    visit goods_received_url(@goods_received)
    click_on "Edit this goods received", match: :first

    fill_in "Date received", with: @goods_received.date_received
    check "Deleted" if @goods_received.deleted
    fill_in "Ext number", with: @goods_received.ext_number
    fill_in "Grv number", with: @goods_received.grv_number
    fill_in "Supplier", with: @goods_received.supplier_id
    fill_in "User", with: @goods_received.user_id
    click_on "Update Goods received"

    assert_text "Goods received was successfully updated"
    click_on "Back"
  end

  test "should destroy Goods received" do
    visit goods_received_url(@goods_received)
    click_on "Destroy this goods received", match: :first

    assert_text "Goods received was successfully destroyed"
  end
end

require "test_helper"

class GoodsReceivedsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @goods_received = goods_receiveds(:one)
  end

  test "should get index" do
    get goods_receiveds_url
    assert_response :success
  end

  test "should get new" do
    get new_goods_received_url
    assert_response :success
  end

  test "should create goods_received" do
    assert_difference("GoodsReceived.count") do
      post goods_receiveds_url, params: { goods_received: { date_received: @goods_received.date_received, deleted: @goods_received.deleted, ext_number: @goods_received.ext_number, grv_number: @goods_received.grv_number, supplier_id: @goods_received.supplier_id, user_id: @goods_received.user_id } }
    end

    assert_redirected_to goods_received_url(GoodsReceived.last)
  end

  test "should show goods_received" do
    get goods_received_url(@goods_received)
    assert_response :success
  end

  test "should get edit" do
    get edit_goods_received_url(@goods_received)
    assert_response :success
  end

  test "should update goods_received" do
    patch goods_received_url(@goods_received), params: { goods_received: { date_received: @goods_received.date_received, deleted: @goods_received.deleted, ext_number: @goods_received.ext_number, grv_number: @goods_received.grv_number, supplier_id: @goods_received.supplier_id, user_id: @goods_received.user_id } }
    assert_redirected_to goods_received_url(@goods_received)
  end

  test "should destroy goods_received" do
    assert_difference("GoodsReceived.count", -1) do
      delete goods_received_url(@goods_received)
    end

    assert_redirected_to goods_receiveds_url
  end
end

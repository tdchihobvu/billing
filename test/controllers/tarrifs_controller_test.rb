require "test_helper"

class TarrifsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tarrif = tarrifs(:one)
  end

  test "should get index" do
    get tarrifs_url
    assert_response :success
  end

  test "should get new" do
    get new_tarrif_url
    assert_response :success
  end

  test "should create tarrif" do
    assert_difference("Tarrif.count") do
      post tarrifs_url, params: { tarrif: { amount: @tarrif.amount, industry_id: @tarrif.industry_id, name: @tarrif.name } }
    end

    assert_redirected_to tarrif_url(Tarrif.last)
  end

  test "should show tarrif" do
    get tarrif_url(@tarrif)
    assert_response :success
  end

  test "should get edit" do
    get edit_tarrif_url(@tarrif)
    assert_response :success
  end

  test "should update tarrif" do
    patch tarrif_url(@tarrif), params: { tarrif: { amount: @tarrif.amount, industry_id: @tarrif.industry_id, name: @tarrif.name } }
    assert_redirected_to tarrif_url(@tarrif)
  end

  test "should destroy tarrif" do
    assert_difference("Tarrif.count", -1) do
      delete tarrif_url(@tarrif)
    end

    assert_redirected_to tarrifs_url
  end
end

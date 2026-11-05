require "test_helper"

class VatTypesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @vat_type = vat_types(:one)
  end

  test "should get index" do
    get vat_types_url
    assert_response :success
  end

  test "should get new" do
    get new_vat_type_url
    assert_response :success
  end

  test "should create vat_type" do
    assert_difference("VatType.count") do
      post vat_types_url, params: { vat_type: { name: @vat_type.name, rate: @vat_type.rate } }
    end

    assert_redirected_to vat_type_url(VatType.last)
  end

  test "should show vat_type" do
    get vat_type_url(@vat_type)
    assert_response :success
  end

  test "should get edit" do
    get edit_vat_type_url(@vat_type)
    assert_response :success
  end

  test "should update vat_type" do
    patch vat_type_url(@vat_type), params: { vat_type: { name: @vat_type.name, rate: @vat_type.rate } }
    assert_redirected_to vat_type_url(@vat_type)
  end

  test "should destroy vat_type" do
    assert_difference("VatType.count", -1) do
      delete vat_type_url(@vat_type)
    end

    assert_redirected_to vat_types_url
  end
end

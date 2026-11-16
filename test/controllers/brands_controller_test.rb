require "test_helper"

class BrandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @brand = brands(:one)
  end

  test "should get index" do
    get brands_url
    assert_response :success
  end

  test "should get new" do
    get new_brand_url
    assert_response :success
  end

  test "should create brand" do
    assert_difference("Brand.count") do
      post brands_url, params: { brand: fresh_attributes(@brand) }
    end

    assert_redirected_to brand_url(Brand.last)
  end

  test "should show brand" do
    get brand_url(@brand)
    assert_response :success
  end

  test "should get edit" do
    get edit_brand_url(@brand)
    assert_response :success
  end

  test "should update brand" do
    patch brand_url(@brand), params: { brand: { name: @brand.name } }
    assert_redirected_to brand_url(@brand)
  end

  test "should destroy brand" do
    record = unreferenced_copy(@brand)

    assert_difference("Brand.count", -1) do
      delete brand_url(record)
    end

    assert_redirected_to brands_url
  end

  test "should explain when a brand is in use" do
    assert_no_difference("Brand.count") do
      delete brand_url(brands(:one))
    end

    assert_response :see_other
    assert_equal "This record is in use by other records and cannot be deleted.", flash[:alert]
  end
end

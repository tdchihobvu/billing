require "test_helper"

class RegionalOfficesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @regional_office = regional_offices(:one)
  end

  test "should get index" do
    get regional_offices_url
    assert_response :success
  end

  test "should get new" do
    get new_regional_office_url
    assert_response :success
  end

  test "should create regional_office" do
    assert_difference("RegionalOffice.count") do
      post regional_offices_url, params: { regional_office: { name: @regional_office.name, region_id: @regional_office.region_id } }
    end

    assert_redirected_to regional_office_url(RegionalOffice.last)
  end

  test "should show regional_office" do
    get regional_office_url(@regional_office)
    assert_response :success
  end

  test "should get edit" do
    get edit_regional_office_url(@regional_office)
    assert_response :success
  end

  test "should update regional_office" do
    patch regional_office_url(@regional_office), params: { regional_office: { name: @regional_office.name, region_id: @regional_office.region_id } }
    assert_redirected_to regional_office_url(@regional_office)
  end

  test "should destroy regional_office" do
    assert_difference("RegionalOffice.count", -1) do
      delete regional_office_url(@regional_office)
    end

    assert_redirected_to regional_offices_url
  end
end

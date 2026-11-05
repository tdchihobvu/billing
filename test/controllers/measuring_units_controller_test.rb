require "test_helper"

class MeasuringUnitsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @measuring_unit = measuring_units(:one)
  end

  test "should get index" do
    get measuring_units_url
    assert_response :success
  end

  test "should get new" do
    get new_measuring_unit_url
    assert_response :success
  end

  test "should create measuring_unit" do
    assert_difference("MeasuringUnit.count") do
      post measuring_units_url, params: { measuring_unit: { name: @measuring_unit.name, symbol: @measuring_unit.symbol } }
    end

    assert_redirected_to measuring_unit_url(MeasuringUnit.last)
  end

  test "should show measuring_unit" do
    get measuring_unit_url(@measuring_unit)
    assert_response :success
  end

  test "should get edit" do
    get edit_measuring_unit_url(@measuring_unit)
    assert_response :success
  end

  test "should update measuring_unit" do
    patch measuring_unit_url(@measuring_unit), params: { measuring_unit: { name: @measuring_unit.name, symbol: @measuring_unit.symbol } }
    assert_redirected_to measuring_unit_url(@measuring_unit)
  end

  test "should destroy measuring_unit" do
    assert_difference("MeasuringUnit.count", -1) do
      delete measuring_unit_url(@measuring_unit)
    end

    assert_redirected_to measuring_units_url
  end
end

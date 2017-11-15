require 'test_helper'

class ApikeysControllerTest < ActionController::TestCase
  setup do
    @apikey = apikeys(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:apikeys)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create apikey" do
    assert_difference('Apikey.count') do
      post :create, apikey: { enabled: @apikey.enabled, key: @apikey.key }
    end

    assert_redirected_to apikey_path(assigns(:apikey))
  end

  test "should show apikey" do
    get :show, id: @apikey
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @apikey
    assert_response :success
  end

  test "should update apikey" do
    patch :update, id: @apikey, apikey: { enabled: @apikey.enabled, key: @apikey.key }
    assert_redirected_to apikey_path(assigns(:apikey))
  end

  test "should destroy apikey" do
    assert_difference('Apikey.count', -1) do
      delete :destroy, id: @apikey
    end

    assert_redirected_to apikeys_path
  end
end

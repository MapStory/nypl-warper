class MapsControllerTest < ActionController::TestCase
  fixtures :maps, :roles, :permissions

  test "index all maps" do
    get :index
    assert_response :success
    @maps = assigns(:maps)
   
    assert_not_nil @maps
    assert @maps.length == 2
  end
  
  test "show one map" do
    get :show, :id => maps(:map1).id
    assert_response :success
    @map = assigns(:map)

    assert_not_nil @map
    assert_equal maps(:map1).title, @map.title
  end
  
  test "publish not allowed by admin" do
    sign_in users(:user1)
    get :publish, :to => "publish", :id => maps(:map1).id
    assert_response :redirect
        
    assert_redirected_to root_path
    assert flash[:error].include?("Sorry you do not have permission")
  end
       
 
  test "publish allowed by admin" do
    sign_in users(:adminuser)
   
    get :publish, :to => "publish", :id => maps(:map1).id
    assert_response :redirect
    assert_redirected_to maps(:map1)
    
    @map = assigns(:map)
    assert_equal :publishing, @map.status
    
    assert_redirected_to maps(:map1)
    assert flash[:notice].include?("Map publishing")
  end
    
  test "search for map via title" do
    get :index, :field => "title", :query => "unwarped"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
  end
  
  test "search for map via description" do
    get :index, :field => "description", :query => "second"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
    
    get :index, :field => "description", :query => "unwarped"
    index_maps = assigns(:maps)
    assert_equal false, index_maps.include?(maps(:unloaded))
    
  end
  
  test "search for map via text" do
    get :index, :field => "text", :query => "second"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
    
    get :index, :field => "text", :query => "unwarped"
    index_maps = assigns(:maps)
    assert index_maps.include? maps(:unloaded)
  end
  
  test "search/index maps for year" do
    get :index, :from => 1800, :to => 2000
    index_maps = assigns(:maps)
    
    assert index_maps.include? maps(:unloaded)
    assert index_maps.include? maps(:map1)
    
    get :index, :from => 1800, :to => 1900
    index_maps = assigns(:maps)
    
    assert_equal false, index_maps.include?(maps(:unloaded))
    assert index_maps.include? maps(:map1)
  end


end

Rails.application.routes.draw do

  resources :apikeys

  # API endpoints
  get 'api/v1/maps' => 'api#index'
  get 'api/v1/warped' => 'api#warped'
  get 'api/v1/maps/:id' => 'api#map'


  root 'home#index'
  get '/offline' => 'home#offline', as: 'offline'
  get 'login' => 'home#login', as: 'login'
    
  resources :users, :except => [:new, :create] do
    member do
      put 'enable'
      put 'disable'
      put 'disable_and_reset'
      put 'force_confirm'
    end
    collection do
      get 'stats'
    end
    resource :user_account
    resources :roles
  end
  
  get '/admin/' => 'admins#index', :as => "admin"

  get '/maps/activity' => 'versions#for_map_model', :as => "maps_activity"
  
  resources :maps do
    member do
      get 'export'
      get 'warp'
      get 'clip'
      post 'rectify'
      get 'align'
      get 'warped'
      get 'metadata'
      get 'status'
      get 'publish'
      get 'unpublish'
      post 'save_mask_and_warp'
      delete 'delete_mask'
      post 'warp_aligned'
      get 'gcps'
      get 'rough_state' => 'maps#get_rough_state'
      post 'rough_state' => 'maps#set_rough_state'
      get 'rough_centroid'=> 'maps#get_rough_centroid'
      post 'rough_centroid' => 'maps#set_rough_centroid'
      get 'id'
      get 'trace'
      get 'idland'
      get 'thumb'
      get 'download'
    end
    collection do
        get 'geosearch'
        get 'tag'
    end
    resources :layers
  end
    
  get '/gcps/' => 'gcp#index', :as => "gcps"
  get '/gcps/:id' => 'gcps#show', :as => "gcp"
  delete '/gcps/:id/destroy' => 'gcps#destroy', :as => "destroy_gcp"
  post '/gcps/add/:mapid' => 'gcps#add', :as => "add_gcp"
  put '/gcps/update/:id' => 'gcps#update', :as => "update_gcp"
  put '/gcps/update_field/:id' => 'gcps#update_field', :as => "update_field_gcp"

  put 'gcps/update' => 'gcps#update', :as => "update_gcp_base"
  put 'gcps/update_field' => 'gcps#update', :as => "update_field_gcp_base" 

  get '/maps/wms/:id' => "maps#wms", :as => 'wms_map'
  get '/maps/tile/:id/:z/:x/:y' => "maps#tile", :as => 'tile_map'
  
  get '/layers/wms/:id' => "layers#wms", :as => "wms_layer"
  get '/layers/wms' => "layers#wms", :as => "wms_layer_base"

  get '/layers/tile/:id/:z/:x/:y' => "layers#tile", :as => 'tile_layer'
  
  resources :layers, :except => [:edit, :update, :destroy, :new, :create] do
    member do
      get 'merge'
      get 'publish'
      get 'toggle_visibility'
      patch 'update_year'
      get 'wms'
      get 'wms2'
      get 'maps'
      get 'export'
      get 'metadata'
      get 'delete'
      get 'id'
      get 'trace'
      get 'idland'
      get 'digitize'
    end
    collection do 
      get 'geosearch'
    end
  end
  
  put '/layers/:id/remove_map/:map_id' => 'layers#remove_map', :as => 'remove_layer_map'
  put '/layers/:id/merge' => 'layers#merge', :as => 'do_merge_layer'
  
  get '/users/:user_id/maps' => 'my_maps#list', :as => 'my_maps'
  post '/users/:user_id/maps/create/:map_id' => 'my_maps#create', :as => 'add_my_map'
  post '/users/:user_id/maps/destroy/:map_id' => 'my_maps#destroy', :as => 'destroy_my_map'

  get '/users/:id/activity' => 'versions#for_user', :as => 'user_activity'
  
  
  get '/maps/acitvity.:format' => 'versions#for_map_model', :as => "formatted_maps_activity"
  get '/maps/:id/activity' => 'versions#for_map', :as => "map_activity"
  get '/maps/:id/activity.:format' => 'versions#for_map', :as => "formatted_map_activity"
  put '/versions/:id/revert_map' => 'versions#revert_map', :as => "revert_map"
  put '/versions/:id/revert_gcp' => 'versions#revert_gcp', :as => "revert_gcp"

  get '/activity' => 'versions#index', :as => "activity"
  get '/activity/:id' => 'versions#show', :as => "activity_details"
  get '/activity.:format' => 'versions#index', :as => "formatted_activity"

    
  resources :groups 
  
  get '/groups/:group_id/users/new' => 'memberships#new', :as => 'new_group_user'
  delete '/groups/:group_id/users/destroy/:id' => 'memberships#destroy', :as => 'destroy_group_user'
  get '/groups/:group_id/users' => 'users#index_for_group', :as => 'group_users'
  get '/groups/:group_id/map' => 'maps#index_for_map', :as => 'group_maps'

  
  get '/digitize/subtype' => 'digitize#subtype'
   
 
end

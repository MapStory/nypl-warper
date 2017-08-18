class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  # Most of the time, try to log in.
  # in some cases we'll want to skip this
  before_filter :login_from_mapstory

  after_filter :set_access_control_headers
  
  helper_method :user_signed_in?, :current_user, :admin_authorized?

  def info_for_paper_trail
    { :ip => request.remote_ip, :user_agent => request.user_agent }
  end
    
  def check_super_user_role
    check_role('super user')
  end

  def check_administrator_role
    check_role("administrator")
  end

  def check_developer_role
    check_role("developer")
  end

  # Returns true if current user has the administrator role
  def admin_authorized?
    user_signed_in? && @current_user.has_role?('administrator')
  end



  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  # Debugging method to check for a MapStory Cookie
  # Call with a before_filter.
  def check_cookie
    Rails.logger.info "Checking for MapStory cookie"

    if cookies[:msid]
      Rails.logger.info "-- We have a msid cookie"
      decoded_value = MapstoryCookie.decode(cookies[:msid])
      Rails.logger.info "-- Our decoded value is: " + decoded_value.inspect
      return decoded_value
    else
      Rails.logger.info "-- No cookie detected"
      return false
    end
  end


  protected


  # Triggers a redirect to permission denied if role check fails
  def check_role(role)
    unless user_signed_in? && @current_user.has_role?(role)
      permission_denied
    end
  end

  def permission_denied
    flash[:error] = "Sorry you do not have permission to view that."
    redirect_to root_path
  end
  

  # stub method until we get SSO hooked up
  def user_signed_in?
    @current_user.present?
  end

  def user_enabled?
    user_signed_in? and @current_user.enabled?
  end

  # returns nil if not set
  def current_user
    @current_user
  end

  # stub Method until we get SSO hooked up
  def authenticate_user!
    true
  end

  # Logs in via cookie if set
  def login_from_mapstory
    Rails.logger.debug "Looking for MapStory cookie to login with"

    if cookies[:msid]
      mapstory_username = MapstoryCookie.decode(cookies[:msid])
      if mapstory_username
        user = User.find_by_login(mapstory_username)

        if user.nil?
          Rails.logger.info "Creating new warper account for #{mapstory_username} from MapStory Cookie"
          user = User.new(:login => mapstory_username)
          user.enabled = true
          user.save
        else
          Rails.logger.info "Found existing account for #{mapstory_username} from MapStory Cookie"
        end

        @current_user = user
      end
    end
  end

  # Remove mapstory cookie
  def logout
    cookies.delete :msid, :domain => "mapstory.org"
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_to login_path
  end


end



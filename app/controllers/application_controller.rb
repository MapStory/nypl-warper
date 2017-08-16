class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  after_filter :set_access_control_headers
  
  helper_method :user_signed_in?, :current_user

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


  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  protected


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
    true
  end

  # stub Method until we get SSO hooked up
  def current_user
    @current_user = User.all.first
  end

  # stub Method until we get SSO hooked up
  def authenticate_user!
    true
  end

end



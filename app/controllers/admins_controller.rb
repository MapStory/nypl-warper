class AdminsController < ApplicationController
  layout 'application'
  
  before_filter :authenticate_user!

  before_filter :check_administrator_role

  def index
    @html_title = "Admin - "
  endread
    
  #
  # Action used by Rack Attack for throttling behaviour testing
  #
  def throttle_test
    render :text => "throttle test"
  end

  
end

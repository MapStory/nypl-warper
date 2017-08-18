class HomeController < ApplicationController

  layout 'application'
  
  def index
    @html_title =  "Home - "
    
    @maps = Map.where(:status => 4).order(:updated_at =>  :desc).limit(3).includes(:gcps)
    
    @layers = Layer.all.order(:updated_at => :desc).limit(3).includes(:maps)
        
    @my_maps = @current_user.maps.order(:updated_at => :desc).limit(3) if @current_user
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @maps }
    end
  end

  # Just a placeholder page to instruct users to log
  # in at MapStory
  def login

    # Generate a cookie using the debug:make_cookie task
    # login user for next request
    if Rails.env.development?
      cookies[:msid] = "dlee:a95b7769b76795fcdd502c36e153ae2c16cf76f5"
    end
  end


end

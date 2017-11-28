class ApikeysController < ApplicationController
  # You must be an administrator to manage api keys
  before_filter :check_administrator_role

  before_action :set_apikey, only: [:show, :edit, :update, :destroy]

  # GET /apikeys
  # GET /apikeys.json
  def index
    @apikeys = Apikey.all
  end

  # GET /apikeys/1
  # GET /apikeys/1.json
  def show
  end

  # GET /apikeys/new
  def new
    @apikey = Apikey.new

    # Default values (user can override)
    @apikey.key = SecureRandom.hex(16)
    @apikey.enabled = true
  end

  # GET /apikeys/1/edit
  def edit
  end

  # POST /apikeys
  # POST /apikeys.json
  def create
    @apikey = Apikey.new(apikey_params)

    respond_to do |format|
      if @apikey.save
        format.html { redirect_to @apikey, notice: 'API key was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /apikeys/1
  # PATCH/PUT /apikeys/1.json
  def update
    respond_to do |format|
      if @apikey.update(apikey_params)
        format.html { redirect_to @apikey, notice: 'API key was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /apikeys/1
  # DELETE /apikeys/1.json
  def destroy
    @apikey.destroy
    respond_to do |format|
      format.html { redirect_to apikeys_url, notice: 'API key was successfully destroyed.' }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_apikey
      @apikey = Apikey.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def apikey_params
      params.require(:apikey).permit(:key, :enabled)
    end
end

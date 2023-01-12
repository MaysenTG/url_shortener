class UrlsController < ApplicationController
  before_action :set_url, only: %i[ edit update destroy ]
  before_action :set_shortened_url, only: %i[ show redirect get_clicks ]

  # GET /urls/new
  def new
    @url = Url.new
  end
  
  # GET /urls/:shortened_url
  def show
  end

  # POST /urls or /urls.json
  def create
    @url = Url.new(url_params)

    respond_to do |format|
      if @url.save
        format.html { redirect_to url_show_path(@url.shortened_url) }
        format.json { render :show, status: :created, location: @url }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @url.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def redirect
    # ActionCable - Broadcast the click to the channel
    
    # Can't cache the redirect, otherwise the click won't be counted
    response.headers["Cache-Control"] = "no-store"
    
    click_counter = ClickCounter.new(url: @url)
    click_counter.update_click
    
    redirect_to @url.original_url, allow_other_host: true
  end
  
  def get_clicks    
    @num_clicks = @url.clicks
  end
  
  def search_url
    shortened_url = params[:short_url].split("/").last
    
    redirect_to url_show_path(shortened_url)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_url
      @url = Url.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def url_params
      params.require(:url).permit(:original_url)
    end
    
    def set_shortened_url
      @shortened_url = params[:shortened_url] || params[:id]
      @url = Url.find_by(shortened_url: @shortened_url)
      
      if @url.nil?
        redirect_invalid
      end
    end
    
    # If the @url is invalid/nil, then redirect to the main page and show an error
    def redirect_invalid
      if @shortened_url.nil?
        notice = "That URL does not exist."
      else
        notice = "The URL <strong>#{@shortened_url}</strong> does not exist."
      end
      redirect_to root_path, notice: notice
    end
end

require "digest"

class UrlsController < ApplicationController
  before_action :set_shortened_url, only: %i[show redirect get_clicks]

  # GET /urls/new
  def new
    @url = Url.new
  end

  # GET /urls/:shortened_url
  def show
    @top_referrers = @url.top_referrers
    @clicks_by_day = @url.clicks_by_day
    @short_link = "#{request.base_url}/#{@url.shortened_url}"
  end

  # POST /urls or /urls.json
  def create
    @url = Url.new(url_params)

    respond_to do |format|
      if @url.save
        format.html { redirect_to url_show_path(@url.shortened_url) }
        format.json { render :show, status: :created, location: url_show_url(@url.shortened_url) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @url.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /urls/validate?field=original_url|custom_code&value=...
  def validate
    field = params[:field].to_s
    unless %w[original_url custom_code].include?(field)
      return render json: { valid: false, errors: ["Unknown field"] }, status: :unprocessable_entity
    end

    errors = Url.validation_errors_for(field, params[:value])
    render json: { valid: errors.empty?, errors: errors }
  end

  def redirect
    if @url.expired?
      redirect_to root_path, notice: "That short link has expired."
      return
    end

    response.headers["Cache-Control"] = "no-store"

    RecordClickJob.perform_later(@url.id, click_metadata)

    redirect_to @url.original_url, allow_other_host: true, status: 302
  end

  def get_clicks
    payload = {
      click_count: @url.clicks,
      unique_clicks: @url.unique_clicks,
      last_clicked_at: @url.last_clicked_at,
      first_clicked_at: @url.first_clicked_at,
      expired: @url.expired?,
      clicks_by_day: @url.clicks_by_day
    }

    respond_to do |format|
      format.html { redirect_to url_show_path(@url.shortened_url) }
      format.json { render json: payload }
    end
  end

  def search_url
    raw = params[:short_url].to_s
    shortened_url = raw.split("/").last.presence

    if shortened_url.blank?
      redirect_to root_path, notice: "Enter a short URL to track."
      return
    end

    redirect_to url_show_path(shortened_url)
  end

  private

  def url_params
    params.require(:url).permit(:original_url, :custom_code, :expires_at)
  end

  def set_shortened_url
    @shortened_url = params[:shortened_url] || params[:id]
    @url = Url.select(
      :id,
      :original_url,
      :shortened_url,
      :clicks,
      :unique_clicks,
      :first_clicked_at,
      :last_clicked_at,
      :expires_at,
      :custom,
      :created_at,
      :updated_at
    ).find_by(shortened_url: @shortened_url)

    redirect_invalid if @url.nil?
  end

  def redirect_invalid
    notice = if @shortened_url.blank?
      "That URL does not exist."
    else
      "The URL #{@shortened_url} does not exist."
    end
    redirect_to root_path, notice: notice
  end

  def click_metadata
    {
      referrer: request.referer,
      user_agent: request.user_agent,
      ip_hash: hashed_ip(request.remote_ip),
      country: request.get_header("HTTP_CF_IPCOUNTRY").presence
    }
  end

  def hashed_ip(ip)
    return if ip.blank?

    Digest::SHA256.hexdigest("#{ip}:#{Rails.application.secret_key_base}")
  end
end

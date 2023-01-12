class ClickCounter
  def initialize(url:)
    @url = url
  end
  
  def update_click
    @url.clicks += 1
    @url.save!

    channel_name = "click_channel_#{@url.shortened_url}"
    
    ActionCable.server.broadcast(
      channel_name,
      {
        click_count: @url.clicks,
      }
    )
  end
end
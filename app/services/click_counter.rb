class ClickCounter
  def initialize(id:)
    @id = id
  end
  
  def update_click
    url = Url.find(@id)
    
    url.clicks += 1
    url.save!

    channel_name = "click_channel_#{url.shortened_url}"
    
    ActionCable.server.broadcast(
      channel_name,
      {
        click_count: url.clicks,
      }
    )
  end
end
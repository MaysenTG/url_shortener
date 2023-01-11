class ClickChannel < ApplicationCable::Channel
  def subscribed
    stream_from "click_channel_#{params[:shortened_url]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

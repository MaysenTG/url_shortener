class ClickChannel < ApplicationCable::Channel
  def subscribed
    stream_from "click_channel_#{params[:shortened_url]}"
    transmit_current_counts
  end

  def sync(_data = nil)
    transmit_current_counts
  end

  def unsubscribed
  end

  private

  def transmit_current_counts
    url = Url.select(:clicks, :unique_clicks, :first_clicked_at, :last_clicked_at)
             .find_by(shortened_url: params[:shortened_url])
    return unless url

    transmit(
      {
        click_count: url.clicks,
        unique_clicks: url.unique_clicks,
        first_clicked_at: url.first_clicked_at&.iso8601,
        last_clicked_at: url.last_clicked_at&.iso8601
      }
    )
  end
end

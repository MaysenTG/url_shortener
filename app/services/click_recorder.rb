class ClickRecorder
  BOT_UA = /bot|crawl|spider|slurp|facebookexternalhit|preview|wget|curl|python-requests|headlesschrome|ahrefs|semrush|bingpreview/i

  def initialize(url:, metadata: {})
    @url = url
    @metadata = metadata.with_indifferent_access
  end

  def call
    now = Time.current
    bot = bot?
    ip_hash = @metadata[:ip_hash].presence

    click_count = nil
    unique_clicks = nil
    first_clicked_at = nil
    last_clicked_at = nil

    Url.transaction do
      locked = Url.lock.find(@url.id)

      unique_visitor = !bot && ip_hash.present? && !LinkClick.exists?(url_id: locked.id, ip_hash: ip_hash, bot: false)

      LinkClick.create!(
        url: locked,
        clicked_at: now,
        referrer: truncate(@metadata[:referrer], 2048),
        user_agent: truncate(@metadata[:user_agent], 512),
        ip_hash: ip_hash,
        country: truncate(@metadata[:country], 8),
        bot: bot
      )

      unless bot
        Url.where(id: locked.id).update_all(
          [
            "clicks = clicks + 1, unique_clicks = unique_clicks + ?, last_clicked_at = ?, first_clicked_at = COALESCE(first_clicked_at, ?)",
            unique_visitor ? 1 : 0,
            now,
            now
          ]
        )
      end

      click_count, unique_clicks, first_clicked_at, last_clicked_at =
        Url.where(id: locked.id).pick(:clicks, :unique_clicks, :first_clicked_at, :last_clicked_at)
    end

    ActionCable.server.broadcast(
      "click_channel_#{@url.shortened_url}",
      {
        click_count: click_count,
        unique_clicks: unique_clicks,
        first_clicked_at: first_clicked_at&.iso8601,
        last_clicked_at: last_clicked_at&.iso8601
      }
    )

    {
      click_count: click_count,
      unique_clicks: unique_clicks,
      bot: bot
    }
  end

  private

  def bot?
    user_agent = @metadata[:user_agent].to_s
    user_agent.blank? || user_agent.match?(BOT_UA)
  end

  def truncate(value, max)
    return if value.blank?

    value.to_s.truncate(max, omission: "")
  end
end

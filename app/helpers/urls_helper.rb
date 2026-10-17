module UrlsHelper
  SAFE_REFERRER = %r{\Ahttps?://}i

  def safe_referrer_url(referrer)
    return if referrer.blank?
    return unless referrer.match?(SAFE_REFERRER)

    referrer
  end

  def qr_code_image_url(text, size: 160)
    "https://api.qrserver.com/v1/create-qr-code/?size=#{size}x#{size}&data=#{ERB::Util.url_encode(text)}"
  end

  def max_daily_clicks(days)
    [days.map { |d| d[:count] }.max.to_i, 1].max
  end
end

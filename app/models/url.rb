require "uri"

class Url < ApplicationRecord
  RESERVED_CODES = %w[
    cable contact rails urls url assets packs up health
    search_url robots sitemap
  ].freeze

  # 1–32 chars: start/end alphanumeric; hyphens/underscores allowed in between.
  CUSTOM_CODE_FORMAT = /\A[a-z0-9](?:[a-z0-9_-]{0,30}[a-z0-9])?\z/i
  ORIGINAL_URL_FORMAT = %r{
    \Ahttps?://
    (
      localhost
      | (\d{1,3}\.){3}\d{1,3}
      | [a-z0-9]+([\-.][a-z0-9]+)*\.[a-z]{2,}
    )
    (:\d{1,5})?
    (/[^\s]*)?
    \z
  }ix

  has_many :link_clicks, dependent: :destroy

  attr_accessor :custom_code

  before_validation :normalize_custom_code
  before_create :assign_shortened_url

  validates :original_url, presence: { message: "Enter a URL to shorten" }
  validates :original_url, format: {
    with: ORIGINAL_URL_FORMAT,
    message: "Enter a valid URL starting with http:// or https://"
  }, allow_blank: true
  validates :custom_code, format: {
    with: CUSTOM_CODE_FORMAT,
    message: "Use 1–32 characters: letters, numbers, hyphens, or underscores"
  }, allow_blank: true
  validate :custom_code_must_be_available, if: -> { custom_code.present? }
  validate :expires_at_must_be_future, if: -> { expires_at.present? && (new_record? || expires_at_changed?) }

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.validation_errors_for(field, value)
    case field.to_s
    when "original_url"
      record = new(original_url: value.to_s.strip)
      record.validate
      record.errors[:original_url]
    when "custom_code"
      record = new(original_url: "https://example.com", custom_code: value)
      record.validate
      record.errors[:custom_code]
    else
      ["Unknown field"]
    end
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def top_referrers(limit: 5)
    link_clicks
      .where(bot: false)
      .where.not(referrer: [nil, ""])
      .group(:referrer)
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(limit)
      .count
  end

  def clicks_by_day(days: 7)
    start_date = (days - 1).days.ago.to_date
    counts = link_clicks
      .where(bot: false, clicked_at: start_date.beginning_of_day..)
      .group("DATE(clicked_at)")
      .count

    (start_date..Date.current).map do |day|
      { date: day, count: counts[day] || counts[day.to_s] || 0 }
    end
  end

  private

  def normalize_custom_code
    self.custom_code = custom_code.to_s.strip.downcase.presence
  end

  def assign_shortened_url
    if custom_code.present?
      self.shortened_url = custom_code
      self.custom = true
    else
      self.shortened_url = generate_short_url
      self.shortened_url = generate_short_url until self.class.find_by(shortened_url: shortened_url).nil?
      self.custom = false
    end
  end

  def generate_short_url
    rand(36**8).to_s(36)
  end

  def custom_code_must_be_available
    code = custom_code
    if RESERVED_CODES.include?(code)
      errors.add(:custom_code, "\"#{code}\" is reserved and can't be used as a short URL")
    elsif self.class.exists?(shortened_url: code)
      errors.add(:custom_code, "This short URL already exists and you can't use it")
    end
  end

  def expires_at_must_be_future
    errors.add(:expires_at, "must be in the future") if expires_at <= Time.current
  end
end

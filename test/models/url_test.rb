require "test_helper"

class UrlTest < ActiveSupport::TestCase
  test "assigns a random shortened url" do
    url = Url.create!(original_url: "https://example.com/auto")
    assert url.shortened_url.present?
    assert_not url.custom
  end

  test "accepts a custom code" do
    url = Url.create!(original_url: "https://example.com/c", custom_code: "Launch-2026")
    assert_equal "launch-2026", url.shortened_url
    assert url.custom
  end

  test "accepts short two-character custom codes" do
    url = Url.create!(original_url: "https://example.com/ab", custom_code: "ab")
    assert_equal "ab", url.shortened_url
  end

  test "rejects invalid custom codes" do
    url = Url.new(original_url: "https://example.com/c", custom_code: "-bad")
    assert_not url.valid?
    assert_match(/letters, numbers/i, url.errors[:custom_code].join)
  end

  test "reports a specific message when short code is taken" do
    url = Url.new(original_url: "https://example.com/c", custom_code: urls(:one).shortened_url)
    assert_not url.valid?
    assert_equal "This short URL already exists and you can't use it", url.errors[:custom_code].first
  end

  test "expired? respects expires_at" do
    url = urls(:one)
    url.update!(expires_at: 1.minute.ago)
    assert url.expired?
  end

  test "clicks_by_day returns seven entries" do
    assert_equal 7, urls(:one).clicks_by_day.size
  end
end


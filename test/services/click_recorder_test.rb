require "test_helper"

class ClickRecorderTest < ActiveSupport::TestCase
  setup do
    @url = urls(:one)
  end

  test "records a link click and atomically increments counters" do
    assert_difference -> { LinkClick.count } => 1, -> { @url.reload.clicks } => 1 do
      ClickRecorder.new(
        url: @url,
        metadata: {
          referrer: "https://news.example/article",
          user_agent: "Mozilla/5.0",
          ip_hash: "visitor-1",
          country: "NZ"
        }
      ).call
    end

    @url.reload
    click = @url.link_clicks.order(:id).last

    assert_equal 2, @url.unique_clicks
    assert_equal "https://news.example/article", click.referrer
    assert_equal "NZ", click.country
    assert_not click.bot
    assert_not_nil @url.first_clicked_at
    assert_not_nil @url.last_clicked_at
  end

  test "does not double-count unique visitors for the same ip hash" do
    metadata = { user_agent: "Mozilla/5.0", ip_hash: "same-visitor" }

    ClickRecorder.new(url: @url, metadata: metadata).call
    ClickRecorder.new(url: @url, metadata: metadata).call

    @url.reload
    assert_equal 3, @url.clicks
    assert_equal 2, @url.unique_clicks
  end

  test "stores bot and blank-ua clicks without incrementing human counters" do
    starting_clicks = @url.clicks
    starting_unique = @url.unique_clicks

    ClickRecorder.new(
      url: @url,
      metadata: { user_agent: "Googlebot/2.1", ip_hash: "bot-1" }
    ).call

    ClickRecorder.new(
      url: @url,
      metadata: { user_agent: "", ip_hash: "blank-ua" }
    ).call

    @url.reload
    assert_equal starting_clicks, @url.clicks
    assert_equal starting_unique, @url.unique_clicks
    assert_equal 2, @url.link_clicks.where(bot: true).count
  end
end

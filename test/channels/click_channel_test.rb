require "test_helper"

class ClickChannelTest < ActionCable::Channel::TestCase
  test "subscribes and transmits current counts" do
    url = urls(:one)

    subscribe shortened_url: url.shortened_url

    assert subscription.confirmed?
    assert_has_stream "click_channel_#{url.shortened_url}"

    assert_equal url.clicks, transmissions.last["click_count"]
    assert_equal url.unique_clicks, transmissions.last["unique_clicks"]
    assert transmissions.last.key?("last_clicked_at")
  end

  test "sync retransmits current counts" do
    url = urls(:one)
    subscribe shortened_url: url.shortened_url
    transmissions.clear

    perform :sync

    assert_equal url.clicks, transmissions.last["click_count"]
  end
end

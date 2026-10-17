require "test_helper"

class UrlsHelperTest < ActionView::TestCase
  test "safe_referrer_url allows http(s) only" do
    assert_equal "https://example.com/a", safe_referrer_url("https://example.com/a")
    assert_nil safe_referrer_url("javascript:alert(1)")
    assert_nil safe_referrer_url("ftp://files.example")
  end
end

require "application_system_test_case"

class UrlsTest < ApplicationSystemTestCase
  test "creating a short url" do
    visit root_url

    fill_in "original_url", with: "https://example.com/system-test"
    click_on "Create short link"

    assert_text "Your short link is"
    assert_selector "[data-controller='click-stats']"
  end
end

require "test_helper"

class UrlsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @url = urls(:one)
  end

  test "should get new" do
    get new_url_url
    assert_response :success
  end

  test "should create url with auto short code" do
    assert_difference("Url.count") do
      post urls_url, params: { url: { original_url: "https://example.com/new-path" } }
    end

    assert_redirected_to url_show_path(Url.order(:id).last.shortened_url)
  end

  test "should create url with custom short code" do
    assert_difference("Url.count") do
      post urls_url, params: {
        url: {
          original_url: "https://example.com/custom",
          custom_code: "my-promo"
        }
      }
    end

    created = Url.order(:id).last
    assert_equal "my-promo", created.shortened_url
    assert created.custom
    assert_redirected_to url_show_path("my-promo")
  end

  test "should reject reserved custom code" do
    assert_no_difference("Url.count") do
      post urls_url, params: {
        url: {
          original_url: "https://example.com/x",
          custom_code: "contact"
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should show url by shortened code" do
    get url_show_path(@url.shortened_url)
    assert_response :success
    assert_select "[data-controller='click-stats']"
  end

  test "redirect enqueues job and returns 302" do
    assert_enqueued_jobs 1, only: RecordClickJob do
      get "/#{@url.shortened_url}", headers: { "User-Agent" => "Mozilla/5.0" }
    end

    assert_redirected_to @url.original_url
  end

  test "expired url does not redirect to destination" do
    @url.update!(expires_at: 1.hour.ago)

    assert_no_enqueued_jobs only: RecordClickJob do
      get "/#{@url.shortened_url}"
    end

    assert_redirected_to root_path
  end

  test "get_clicks html redirects to show" do
    get url_clicks_path(@url.shortened_url)
    assert_redirected_to url_show_path(@url.shortened_url)
  end

  test "get_clicks json returns stats payload" do
    get url_clicks_path(@url.shortened_url, format: :json)
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @url.clicks, body["click_count"]
    assert body.key?("clicks_by_day")
  end

  test "search_url with blank input returns to root" do
    post search_url_path, params: { short_url: "" }
    assert_redirected_to root_path
  end

  test "invalid short code notice is escaped" do
    get "/%3Cscript%3Ealert(1)%3C/script%3E"
    follow_redirect!
    assert_response :success
    assert_no_match %r{<script>alert\(1\)</script>}, response.body
  end

  test "index is not available" do
    get "/urls"
    assert_response :redirect
  end
end

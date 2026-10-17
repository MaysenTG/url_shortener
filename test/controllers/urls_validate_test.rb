require "test_helper"

class UrlsValidateTest < ActionDispatch::IntegrationTest
  test "original_url validation rejects invalid urls" do
    get validate_urls_path, params: { field: "original_url", value: "not-a-url" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_not body["valid"]
    assert_match(/valid URL/i, body["errors"].first)
  end

  test "original_url validation accepts http urls" do
    get validate_urls_path, params: { field: "original_url", value: "https://example.com/path" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["valid"]
    assert_empty body["errors"]
  end

  test "custom_code validation reports already taken with specific message" do
    existing = urls(:one)

    get validate_urls_path, params: { field: "custom_code", value: existing.shortened_url }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_not body["valid"]
    assert_equal "This short URL already exists and you can't use it", body["errors"].first
  end

  test "custom_code validation reports reserved codes" do
    get validate_urls_path, params: { field: "custom_code", value: "contact" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_not body["valid"]
    assert_match(/reserved/i, body["errors"].first)
  end

  test "blank custom_code is valid" do
    get validate_urls_path, params: { field: "custom_code", value: "" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["valid"]
  end
end

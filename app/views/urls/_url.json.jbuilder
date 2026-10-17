json.extract! url, :id, :original_url, :shortened_url, :clicks, :unique_clicks,
              :first_clicked_at, :last_clicked_at, :expires_at, :custom,
              :created_at, :updated_at
json.expired url.expired?
json.show_url url_show_url(url.shortened_url)

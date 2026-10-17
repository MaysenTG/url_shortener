class RecordClickJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(url_id, metadata = {})
    url = Url.select(:id, :shortened_url).find(url_id)
    ClickRecorder.new(url: url, metadata: metadata).call
  end
end

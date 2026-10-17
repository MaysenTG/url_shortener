require "test_helper"

class RecordClickJobTest < ActiveJob::TestCase
  test "records the click for an existing url" do
    url = urls(:one)

    assert_difference("LinkClick.count") do
      RecordClickJob.perform_now(
        url.id,
        { user_agent: "Mozilla/5.0", ip_hash: "job-visitor" }
      )
    end
  end
end

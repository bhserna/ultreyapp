require "test_helper"

class RetiredRoutesTest < ActionDispatch::IntegrationTest
  RETIRED_ROUTES = {
    get: %w[
      /schedule
      /schedule_entries/1
      /preparations/1
      /operational_activities/1
      /activities/1/activity_detail/new
      /activities/1/activity_detail/edit
      /schedule_entries/1/documents
      /schedule_entries/1/questions
      /questions
      /questions/1/edit
      /questions/1/answer/edit
      /topics
      /topics/1/edit
    ],
    post: %w[
      /activities/1/activity_detail
      /schedule_entries/1/documents
      /schedule_entries/1/questions
      /questions
      /topics
    ],
    patch: %w[
      /activities/1/activity_detail
      /questions/1
      /questions/1/answer
      /topics/1
    ],
    put: %w[
      /activities/1/activity_detail
      /questions/1
      /questions/1/answer
      /topics/1
    ],
    delete: %w[
      /schedule_entries/1/documents/1
      /questions/1
      /topics/1
    ]
  }.freeze

  RETIRED_ROUTES.each do |method, paths|
    paths.each do |path|
      test "#{method.upcase} #{path} returns 404" do
        public_send(method, path)

        assert_response :not_found
        assert_nil response.headers["Location"]
      end
    end
  end
end

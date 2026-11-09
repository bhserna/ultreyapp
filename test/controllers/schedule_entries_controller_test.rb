require "test_helper"

class ScheduleEntriesControllerTest < ActionDispatch::IntegrationTest
  test "reject non-act activities" do
    [ activities(:reception), activities(:chair_setup) ].each do |activity|
      assert_act_endpoints_reject(activity.id)
    end
  end

  test "reject an unknown act" do
    assert_act_endpoints_reject(Activity.maximum(:id) + 1)
  end

  private

  def assert_act_endpoints_reject(id)
    assert_no_difference [ "Question.count", "ProductionDetail.count", "Document.count", "ActiveStorage::Blob.count", "ActiveStorage::Attachment.count" ] do
      [
        schedule_entry_url(id),
        schedule_entry_questions_url(id),
        schedule_entry_documents_url(id),
        new_schedule_entry_production_detail_url(id)
      ].each do |url|
        get url
        assert_response :not_found
      end

      post schedule_entry_questions_url(id), params: { question: { body: "Rejected question" } }
      assert_response :not_found
      post schedule_entry_production_detail_url(id), params: { production_detail: { notes: "Rejected notes" } }
      assert_response :not_found
      post schedule_entry_documents_url(id), params: {
        files: [ fixture_file_upload(Rails.root.join("test/fixtures/files/agenda.txt"), "text/plain") ]
      }
      assert_response :not_found
    end
  end
end

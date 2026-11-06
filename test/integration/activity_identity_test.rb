require "test_helper"

class ActivityIdentityTest < ActionDispatch::IntegrationTest
  test "existing act routes reject operation and preparation action IDs" do
    non_act_activities.each do |activity|
      [
        schedule_entry_url(activity.id),
        schedule_entry_questions_url(activity.id),
        schedule_entry_documents_url(activity.id),
        new_schedule_entry_production_detail_url(activity.id)
      ].each do |url|
        get url
        assert_response :not_found
      end
    end
  end

  test "operations and preparation actions cannot create records through act endpoints" do
    non_act_activities.each do |activity|
      assert_no_difference "Question.count" do
        post schedule_entry_questions_url(activity.id), params: { question: { body: "Wrong activity type" } }
        assert_response :not_found
      end

      assert_no_difference "ProductionDetail.count" do
        post schedule_entry_production_detail_url(activity.id), params: { production_detail: { notes: "Wrong activity type" } }
        assert_response :not_found
      end

      assert_no_difference [ "Document.count", "ActiveStorage::Attachment.count" ] do
        post schedule_entry_documents_url(activity.id), params: {
          files: [ fixture_file_upload("agenda.txt", "text/plain") ]
        }
        assert_response :not_found
      end
    end
  end

  test "operation URLs keep original source IDs rather than accepting other activity IDs" do
    get operational_activity_url(1)
    assert_response :success
    assert_select "h1", text: "Recepción de Diócesis"

    get operational_activity_url(32)
    assert_response :not_found

    get operational_activity_url(Activity.preparation_actions.first.id)
    assert_response :not_found

    get schedule_entry_url(1)
    assert_response :success
    assert_select "h1", text: Activity.find(1).title
  end

  private

  def non_act_activities
    [ Activity.operations.first, Activity.preparation_actions.order(:id).first ]
  end
end

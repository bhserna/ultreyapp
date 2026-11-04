require "test_helper"

class ActivityIdentityTest < ActionDispatch::IntegrationTest
  test "existing act routes reject operation activity IDs" do
    operation = Activity.operations.first

    [
      schedule_entry_url(operation.id),
      schedule_entry_questions_url(operation.id),
      schedule_entry_documents_url(operation.id),
      new_schedule_entry_production_detail_url(operation.id)
    ].each do |url|
      get url
      assert_response :not_found
    end
  end

  test "operations cannot create records through act endpoints" do
    operation = Activity.operations.first

    assert_no_difference "Question.count" do
      post schedule_entry_questions_url(operation.id), params: { question: { body: "Wrong activity type" } }
      assert_response :not_found
    end

    assert_no_difference "ProductionDetail.count" do
      post schedule_entry_production_detail_url(operation.id), params: { production_detail: { notes: "Wrong activity type" } }
      assert_response :not_found
    end

    assert_no_difference [ "Document.count", "ActiveStorage::Attachment.count" ] do
      post schedule_entry_documents_url(operation.id), params: {
        files: [ fixture_file_upload("agenda.txt", "text/plain") ]
      }
      assert_response :not_found
    end
  end

  test "operation URLs keep original source IDs rather than accepting unified activity IDs" do
    get operational_activity_url(1)
    assert_response :success
    assert_select "h1", text: "Recepción de Diócesis"

    get operational_activity_url(32)
    assert_response :not_found

    get schedule_entry_url(1)
    assert_response :success
    assert_select "h1", text: Activity.find(1).title
  end
end

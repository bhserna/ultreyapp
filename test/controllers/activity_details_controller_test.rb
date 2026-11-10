require "test_helper"

class ActivityDetailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActivityDetail.delete_all
  end

  test "create details for each kind using the activity in the URL" do
    each_activity do |activity|
      original = activity.attributes
      values = {
        description: "Instructions", executors: "Stage team", notes: "Saved notes",
        pending_confirmations: "Confirm supplier", screen: "Welcome slide", audio: "Microphone",
        room_lighting: "Dimmed", stage_lighting: "White", aisle_lighting: "On",
        requirements: "Two chairs", radios: "Channel 1", media_files: "Welcome video",
        arena_questions: "Which entrance?", general_questions: "Who coordinates?"
      }

      assert_difference "ActivityDetail.count", 1 do
        assert_no_difference "Question.count" do
          post activity_activity_detail_url(activity), params: {
            activity_detail: values.merge(activity_id: activities(:closing_act).id, act_id: activities(:closing_act).id)
          }
        end
      end

      detail = activity.reload.activity_detail
      assert_equal activity.id, detail.activity_id
      assert_equal values.stringify_keys, detail.attributes.slice(*values.keys.map(&:to_s))
      assert_redirected_to return_path(activity)
      assert_equal original, activity.attributes
    end
  end

  test "update details without changing the activity" do
    each_activity do |activity|
      original_activity = activity.attributes
      detail = activity.create_activity_detail!(notes: "Original notes", audio: "Microphone")
      original = detail.attributes.except("notes", "updated_at")

      patch activity_activity_detail_url(activity), params: {
        activity_detail: { notes: "Updated notes", activity_id: activities(:closing_act).id }
      }

      assert_redirected_to return_path(activity)
      assert_equal "Updated notes", detail.reload.notes
      assert_equal original, detail.attributes.except("notes", "updated_at")
      assert_equal original_activity, activity.reload.attributes
    end
  end

  test "ignore commission assignments submitted through the details form" do
    each_activity do |activity|
      original_commissions = activity.commissions
      post activity_activity_detail_url(activity), params: {
        activity_detail: { notes: "Saved notes", commission: "Other team", commissions: [ "Other team" ] }
      }

      assert_redirected_to return_path(activity)
      assert_equal original_commissions, activity.reload.commissions
      assert_equal "Saved notes", activity.activity_detail.notes
      assert_not activity.activity_detail.has_attribute?(:commission)

      patch activity_activity_detail_url(activity), params: {
        activity_detail: { notes: "Updated notes", commission: "Other team", commissions: [ "Other team" ] }
      }

      assert_redirected_to return_path(activity)
      assert_equal original_commissions, activity.reload.commissions
      assert_equal "Updated notes", activity.activity_detail.notes
    end
  end

  test "reject access to details through an activity without them" do
    detail = activities(:opening_act).create_activity_detail!(notes: "Original notes")
    original = detail.attributes

    [ activities(:closing_act), activities(:reception), activities(:chair_setup) ].each do |other|
      get edit_activity_activity_detail_url(other)
      assert_response :not_found
      patch activity_activity_detail_url(other), params: {
        activity_detail: { id: detail.id, notes: "Tampered notes" }
      }
      assert_response :not_found
    end

    assert_equal original, detail.reload.attributes
  end

  test "reject unknown activities" do
    unknown_id = Activity.maximum(:id) + 1

    get new_activity_activity_detail_url(unknown_id)
    assert_response :not_found
    get edit_activity_activity_detail_url(unknown_id)
    assert_response :not_found
    post activity_activity_detail_url(unknown_id), params: { activity_detail: { notes: "Rejected notes" } }
    assert_response :not_found
    patch activity_activity_detail_url(unknown_id), params: { activity_detail: { notes: "Rejected notes" } }
    assert_response :not_found
  end

  test "reject duplicate details without replacing the existing association" do
    each_activity do |activity|
      detail = activity.create_activity_detail!(notes: "Original notes")
      original = detail.attributes

      assert_no_difference "ActivityDetail.count" do
        post activity_activity_detail_url(activity), params: { activity_detail: { notes: "Duplicate notes" } }
      end

      assert_response :unprocessable_entity
      assert_select "form[action=?]", activity_activity_detail_path(activity)
      assert_select "[role=alert]"
      assert_select "textarea[name='activity_detail[notes]']", text: "Duplicate notes"
      assert_equal original, detail.reload.attributes
    end
  end

  test "redirect new to edit when details already exist" do
    activity = activities(:opening_act)
    activity.create_activity_detail!

    get new_activity_activity_detail_url(activity)

    assert_redirected_to edit_activity_activity_detail_url(activity)
  end

  test "reject deletion of details" do
    activity = activities(:opening_act)
    detail = activity.create_activity_detail!(notes: "Keep these notes")

    assert_no_difference "ActivityDetail.count" do
      delete activity_activity_detail_url(activity)
    end

    assert_response :not_found
    assert_equal "Keep these notes", detail.reload.notes
  end

  private

  def each_activity(&block)
    [ activities(:opening_act), activities(:reception), activities(:chair_setup) ].each(&block)
  end

  def return_path(activity)
    case activity.kind
    when "act" then schedule_entry_path(activity)
    when "operation" then operational_activity_path(activity.source_id)
    when "preparation_action" then preparation_path(activity.preparation_id, anchor: "activity_#{activity.id}")
    end
  end
end

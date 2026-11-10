require "test_helper"

class ActivityDetailTest < ActiveSupport::TestCase
  setup do
    ActivityDetail.delete_all
  end

  test "store general and technical details for every activity kind" do
    attributes = {
      description: "Execution instructions", executors: "Production team",
      notes: "Keep the entrance clear", pending_confirmations: "Confirm supplier",
      screen: "Welcome slide", audio: "Two microphones",
      room_lighting: "Dimmed", stage_lighting: "White", aisle_lighting: "On",
      requirements: "Two chairs", radios: "Channel 1", media_files: "Welcome video",
      arena_questions: "Where is the entrance?",
      general_questions: "Who coordinates?"
    }

    [ activities(:opening_act), activities(:reception), activities(:chair_setup) ].each do |activity|
      detail = activity.create_activity_detail!(attributes)

      assert_equal attributes.stringify_keys, detail.reload.attributes.slice(*attributes.keys.map(&:to_s))
      assert_equal detail, activity.reload.activity_detail
      assert_equal activity, detail.activity
    end
  end

  test "allow activities without details and details without optional content" do
    activity = activities(:opening_act)

    assert_nil activity.activity_detail
    detail = activity.create_activity_detail!
    assert detail.persisted?
    assert_nil detail.description
    assert_nil detail.audio
  end

  test "require an existing activity" do
    detail = ActivityDetail.new

    assert_not detail.valid?
    assert detail.errors.of_kind?(:activity, :blank)

    detail.activity_id = Activity.maximum(:id) + 1
    assert_not detail.valid?
    assert detail.errors.of_kind?(:activity, :blank)
  end

  test "allow one detail per activity" do
    activity = activities(:opening_act)
    activity.create_activity_detail!
    duplicate = ActivityDetail.new(activity: activity)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:activity_id, :taken)

    duplicate.activity = activities(:closing_act)
    assert duplicate.valid?
  end

  test "enforce uniqueness in the database" do
    activity = activities(:opening_act)
    activity.create_activity_detail!

    assert_raises ActiveRecord::RecordNotUnique do
      ActivityDetail.insert_all!([ { activity_id: activity.id } ])
    end
  end

  test "enforce a required activity reference in the database" do
    assert_raises ActiveRecord::NotNullViolation do
      ActivityDetail.insert_all!([ { activity_id: nil } ])
    end

    assert_raises ActiveRecord::InvalidForeignKey do
      ActivityDetail.insert_all!([ { activity_id: Activity.maximum(:id) + 1 } ])
    end
  end

  test "destroy details with their activity" do
    activity = activities(:opening_act)
    detail = activity.create_activity_detail!

    activity.destroy!

    assert detail.destroyed?
    assert_not ActivityDetail.exists?(detail.id)
  end

  test "cascade deletion in the database without model callbacks" do
    activity = activities(:opening_act)
    detail = activity.create_activity_detail!

    activity.delete

    assert_not ActivityDetail.exists?(detail.id)
  end

  test "leave existing information sources unchanged" do
    act = activities(:opening_act)
    ProductionDetail.create!(act_id: act.id, notes: "Original act notes", audio: "Original act audio")
    operation = activities(:reception)
    action = activities(:chair_setup)
    original_details = [ operation, action ].to_h { |activity| [ activity.id, activity.details.deep_dup ] }

    [ act, operation, action ].each do |activity|
      activity.create_activity_detail!(notes: "New notes", audio: "New audio")
    end

    assert_equal "Original act notes", ProductionDetail.find_by!(act_id: act.id).notes
    assert_equal "Original act audio", ProductionDetail.find_by!(act_id: act.id).audio
    [ act, operation, action ].each do |activity|
      assert_equal "New notes", activity.reload.activity_detail.notes
      assert_equal "New audio", activity.activity_detail.audio
    end
    [ operation, action ].each do |activity|
      assert_equal original_details.fetch(activity.id), activity.details
    end
  end
end

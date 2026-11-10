require "test_helper"

class ActivityInformationTest < ActiveSupport::TestCase
  setup do
    ActivityDetail.delete_all
  end

  test "read general and technical information from the same association for all kinds" do
    [ activities(:opening_act), activities(:reception), activities(:chair_setup) ].each do |activity|
      activity.update!(details: { "notes" => "Old JSON notes", "audio" => "Old JSON audio" })
      ProductionDetail.create!(act_id: activity.id, notes: "Old production notes", audio: "Old production audio")
      activity.create_activity_detail!(
        executors: "Assigned team", notes: "Current notes", pending_confirmations: "Confirm supplier",
        audio: "Two microphones", screen: "Welcome video", media_files: "Playlist"
      )

      detail = Activity.find(activity.id).activity_detail
      assert_equal "Assigned team", detail.executors
      assert_equal "Current notes", detail.notes
      assert_equal "Confirm supplier", detail.pending_confirmations
      assert_equal "Two microphones", detail.audio
      assert_equal "Welcome video", detail.screen
      assert_equal "Playlist", detail.media_files
    end
  end

  test "do not fall back to legacy sources when common details are missing" do
    [ activities(:opening_act), activities(:reception), activities(:chair_setup) ].each do |activity|
      activity.update!(details: { "notes" => "Old JSON notes" })
      ProductionDetail.create!(act_id: activity.id, notes: "Old production notes")

      assert_nil activity.reload.activity_detail
    end
  end

  test "reflect changes in fresh instances" do
    activity = activities(:opening_act)
    detail = activity.create_activity_detail!(notes: "Initial notes")
    assert_equal "Initial notes", Activity.find(activity.id).activity_detail.notes

    detail.update!(notes: "Updated notes")
    assert_equal "Updated notes", Activity.find(activity.id).activity_detail.notes

    detail.destroy!
    assert_nil Activity.find(activity.id).activity_detail
  end
end

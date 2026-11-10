require "test_helper"
require Rails.root.join("db/migrate/20261029000000_remove_legacy_activity_details")

class RemoveLegacyActivityDetailsTest < ActiveSupport::TestCase
  setup do
    connection.add_column :activities, :details, :json, default: {}, null: false
    connection.add_column :activity_details, :commission, :text
    connection.create_table :production_details do |table|
      table.integer :act_id, null: false
      %i[executors screen audio room_lighting stage_lighting aisle_lighting requirements notes radios pending_confirmations].each do |field|
        table.text field
      end
      table.timestamps
    end
    reset_source_models
  end

  teardown do
    connection.drop_table :production_details if connection.table_exists?(:production_details)
    connection.remove_column :activities, :details if connection.column_exists?(:activities, :details)
    connection.remove_column :activity_details, :commission if connection.column_exists?(:activity_details, :commission)
    Activity.reset_column_information
    ActivityDetail.reset_column_information
  end

  test "remove legacy storage while preserving current details commissions and questions" do
    act = activities(:opening_act)
    act.create_activity_detail!(notes: "Updated notes", arena_questions: "Editable arena question", general_questions: "Editable general question")
    source_activity(act).update!(details: { "notes" => "Original notes" })
    RemoveLegacyActivityDetails::ProductionDetailRecord.create!(act_id: act.id, notes: "Original production notes")
    question = Question.create!(act_id: act.id, body: "Existing question", answer: "Confirmed")
    original_question = question.attributes
    original_details = ActivityDetail.order(:id).map { |detail| detail.attributes.except("commission") }
    original_commissions = Activity.order(:id).pluck(:id, :commissions)

    cleanup

    assert_not connection.table_exists?(:production_details)
    assert_not connection.column_exists?(:activities, :details)
    assert_not connection.column_exists?(:activity_details, :commission)
    ActivityDetail.reset_column_information
    assert_equal original_details, ActivityDetail.order(:id).map(&:attributes)
    assert_equal original_commissions, Activity.order(:id).pluck(:id, :commissions)
    assert_equal original_question, question.reload.attributes
  end

  test "abort without dropping any sources when unknown JSON keys exist" do
    activity = activities(:reception)
    source_activity(activity).update!(details: { "unmapped_field" => nil })

    error = assert_raises(ActiveRecord::MigrationError) { cleanup }

    assert_includes error.message, "Activity #{activity.id}: unpreserved JSON keys: unmapped_field"
    assert_sources_exist
  end

  test "abort when JSON content has no migrated detail record" do
    activity = activities(:opening_act)
    source_activity(activity).update!(details: { "audio" => "Original audio" })

    error = assert_raises(ActiveRecord::MigrationError) { cleanup }

    assert_includes error.message, "Activity #{activity.id}: migrated details are missing"
    assert_sources_exist
  end

  test "abort when production content has no migrated detail record" do
    production = RemoveLegacyActivityDetails::ProductionDetailRecord.create!(act_id: activities(:opening_act).id, notes: "Original notes")

    error = assert_raises(ActiveRecord::MigrationError) { cleanup }

    assert_includes error.message, "ProductionDetail #{production.id}: migrated details are missing"
    assert_sources_exist
  end

  test "abort when production records have invalid act references or unknown fields" do
    connection.add_column :production_details, :unmapped_field, :text
    RemoveLegacyActivityDetails::ProductionDetailRecord.reset_column_information
    production = RemoveLegacyActivityDetails::ProductionDetailRecord.create!(act_id: activities(:reception).id, unmapped_field: "Keep this")

    error = assert_raises(ActiveRecord::MigrationError) { cleanup }

    assert_includes error.message, "ProductionDetail #{production.id}: invalid act reference"
    assert_includes error.message, "ProductionDetail #{production.id}: unpreserved columns: unmapped_field"
    assert_sources_exist
  end

  test "abort when legacy commission text has not been reconciled" do
    activity = activities(:reception)
    RemoveLegacyActivityDetails::ActivityDetailRecord.find_by!(activity_id: activity.id).update!(commission: "Unreviewed team")

    error = assert_raises(ActiveRecord::MigrationError) { cleanup }

    assert_includes error.message, "Activity #{activity.id}: commission text has not been reconciled"
    assert_sources_exist
  end

  test "reject malformed JSON instead of discarding it" do
    source_activity(activities(:opening_act)).update!(details: [ "Unexpected content" ])
    source_activity(activities(:closing_act)).update!(details: { "notes" => [ "Unexpected array" ] })

    error = assert_raises(ActiveRecord::MigrationError) { cleanup }

    assert_includes error.message, "details must be an object"
    assert_includes error.message, "notes contains nontext source data"
    assert_sources_exist
  end

  test "do not restore stale source values over deliberately cleared fields" do
    activity = activities(:reception)
    source_activity(activity).update!(details: { "notes" => "Old notes", "arena_questions" => "Old question" })
    activity.activity_detail.update!(notes: "", arena_questions: "")

    cleanup

    assert_equal "", activity.activity_detail.reload.notes
    assert_equal "", activity.activity_detail.arena_questions
  end

  test "require a backup rather than pretend deleted data can be rolled back" do
    migration = RemoveLegacyActivityDetails.new
    assert_raises(ActiveRecord::IrreversibleMigration) do
      migration.suppress_messages { migration.migrate(:down) }
    end
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def reset_source_models
    [
      RemoveLegacyActivityDetails::ActivityRecord,
      RemoveLegacyActivityDetails::ActivityDetailRecord,
      RemoveLegacyActivityDetails::ProductionDetailRecord
    ].each(&:reset_column_information)
  end

  def source_activity(activity)
    RemoveLegacyActivityDetails::ActivityRecord.find(activity.id)
  end

  def cleanup
    migration = RemoveLegacyActivityDetails.new
    migration.suppress_messages { migration.migrate(:up) }
  end

  def assert_sources_exist
    assert connection.table_exists?(:production_details)
    assert connection.column_exists?(:activities, :details)
    assert connection.column_exists?(:activity_details, :commission)
  end
end

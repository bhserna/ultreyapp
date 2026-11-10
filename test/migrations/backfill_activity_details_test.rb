require "test_helper"
require Rails.root.join("db/migrate/20261027000000_backfill_activity_details")

class BackfillActivityDetailsTest < ActiveSupport::TestCase
  test "copy production fields and JSON-only fields for acts without changing sources" do
    act = activities(:opening_act)
    act.update!(details: {
      "description" => "Welcome instructions", "media_files" => "Welcome video",
      "commission" => "Production", "arena_questions" => "Which entrance?",
      "general_questions" => "Who coordinates?", "audio" => "Two microphones"
    })
    production = ProductionDetail.create!(
      act_id: act.id, executors: "Stage team", screen: "Welcome slide",
      audio: "Two microphones", room_lighting: "Dimmed", stage_lighting: "White",
      aisle_lighting: "On", requirements: "Two chairs", notes: "Keep entrance clear",
      radios: "Channel 1", pending_confirmations: "Confirm supplier"
    )
    original_act = act.attributes
    original_production = production.attributes

    backfill

    expected = act.details.merge(production.attributes.slice(*BackfillActivityDetails::DETAIL_FIELDS))
    assert_equal expected, act.reload.activity_detail.attributes.slice(*expected.keys)
    assert_equal original_act, act.attributes
    assert_equal original_production, production.reload.attributes
    assert_equal "Two microphones", act.production_detail.audio
  end

  test "copy JSON details for operations and preparation actions" do
    fields = BackfillActivityDetails::DETAIL_FIELDS
    [ activities(:reception), activities(:chair_setup) ].each do |activity|
      activity.update!(details: fields.index_with { |field| "Value for #{field}" })
    end
    originals = [ activities(:reception), activities(:chair_setup) ].to_h do |activity|
      [ activity.id, activity.attributes ]
    end

    backfill

    originals.each do |id, original|
      activity = Activity.find(id)
      assert_equal original.fetch("details"), activity.activity_detail.attributes.slice(*fields)
      assert_equal original, activity.attributes
    end
    assert_equal 0, Question.count
  end

  test "recover JSON content when act production is absent or blank" do
    act = activities(:opening_act)
    act.update!(details: { "notes" => "Recovered notes", "audio" => "Recovered audio" })
    ProductionDetail.create!(act_id: act.id, notes: "", audio: nil)
    other_act = activities(:closing_act)
    other_act.update!(details: { "media_files" => "Closing video" })

    backfill

    assert_equal "Recovered notes", act.reload.activity_detail.notes
    assert_equal "Recovered audio", act.activity_detail.audio
    assert_equal "Closing video", other_act.reload.activity_detail.media_files
  end

  test "skip empty activities and allow null and blank fields" do
    act = activities(:opening_act)
    act.update!(details: { "notes" => nil, "audio" => "", "description" => " " })
    ProductionDetail.create!(act_id: act.id)
    operation = activities(:reception)
    operation.update!(details: { "notes" => "Keep this", "audio" => nil, "screen" => "" })

    backfill

    assert_nil act.reload.activity_detail
    assert_nil activities(:closing_act).activity_detail
    detail = operation.reload.activity_detail
    assert_equal "Keep this", detail.notes
    assert_nil detail.audio
    assert_equal "", detail.screen
  end

  test "abort all copies and report conflicting sources" do
    act = activities(:closing_act)
    act.update!(details: { "audio" => "JSON audio", "notes" => "JSON notes" })
    ProductionDetail.create!(act_id: act.id, audio: "Production audio", notes: "Production notes")

    error = assert_raises(ActiveRecord::MigrationError) { backfill }

    assert_includes error.message, "Activity #{act.id}: production_details and details conflict on audio"
    assert_includes error.message, "conflict on notes"
    assert_equal 0, ActivityDetail.count
    assert_equal "JSON audio", act.reload.details.fetch("audio")
  end

  test "reject unknown keys even when blank instead of discarding them" do
    activity = activities(:reception)
    activity.update!(details: { "unmapped_field" => nil })

    error = assert_raises(ActiveRecord::MigrationError) { backfill }

    assert_includes error.message, "Activity #{activity.id}: unknown details keys: unmapped_field"
    assert_equal 0, ActivityDetail.count
  end

  test "reject JSON values that cannot be copied as text losslessly" do
    activity = activities(:reception)
    activity.update!(details: { "audio" => [ "Microphone", "Speaker" ] })
    action = activities(:chair_setup)
    action.update!(details: [ "Not an object" ])

    error = assert_raises(ActiveRecord::MigrationError) { backfill }

    assert_includes error.message, "Activity #{activity.id}: details.audio must be text or null"
    assert_includes error.message, "Activity #{action.id}: details must be an object"
    assert_equal 0, ActivityDetail.count
  end

  test "reject production details without an act including references to other kinds" do
    orphan = ProductionDetail.create!(act_id: Activity.maximum(:id) + 1)
    wrong_kind = ProductionDetail.create!(act_id: activities(:reception).id)

    error = assert_raises(ActiveRecord::MigrationError) { backfill }

    [ orphan, wrong_kind ].each do |production|
      assert_includes error.message, "ProductionDetail #{production.id}: act_id=#{production.act_id} does not reference an act"
    end
    assert_equal 0, ActivityDetail.count
  end

  test "rerunning the copy preserves existing records and timestamps" do
    backfill
    originals = ActivityDetail.order(:id).map(&:attributes)

    backfill

    assert_equal originals, ActivityDetail.order(:id).map(&:attributes)
  end

  test "fill missing target fields without erasing existing target content" do
    activity = activities(:reception)
    detail = activity.create_activity_detail!(description: "Already entered", notes: "Preparar registros")

    backfill

    assert_equal "Already entered", detail.reload.description
    assert_equal "Preparar registros", detail.notes
    assert_equal "Micrófono de recepción", detail.audio
  end

  test "abort instead of overwriting different existing target content" do
    activity = activities(:reception)
    detail = activity.create_activity_detail!(notes: "Newer target notes")
    original = detail.attributes

    error = assert_raises(ActiveRecord::MigrationError) { backfill }

    assert_includes error.message, "Activity #{activity.id}: activity_details and source data conflict on notes"
    assert_equal original, detail.reload.attributes
    assert_equal 1, ActivityDetail.count
  end

  test "refuse rollback that could delete edited details" do
    migration = BackfillActivityDetails.new
    assert_raises(ActiveRecord::IrreversibleMigration) do
      migration.suppress_messages { migration.migrate(:down) }
    end
  end

  private

  def backfill
    migration = BackfillActivityDetails.new
    migration.suppress_messages { migration.migrate(:up) }
  end
end

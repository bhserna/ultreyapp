require "test_helper"

class ActivityInformationTest < ActiveSupport::TestCase
  test "reads act execution notes and production from the current database record" do
    technical_attributes = ProductionInformation.members.map(&:to_s).excluding("media_files").index_with { |attribute| "Current #{attribute}" }
    record = ProductionDetail.create!(
      schedule_entry_id: 1,
      executors: "Current execution team",
      notes: "Current notes\nSecond line",
      pending_confirmations: "Current pending confirmation",
      **technical_attributes
    )
    activity = Activity.find(1)

    assert_equal record.executors, activity.executors
    assert_equal record.notes, activity.notes
    assert_equal record.pending_confirmations, activity.pending_confirmations
    assert_instance_of ProductionInformation, activity.production_detail
    technical_attributes.each do |attribute, value|
      assert_equal value, activity.production_detail.public_send(attribute)
    end
    assert_nil activity.production_detail.media_files
    assert_not_respond_to activity.production_detail, :executors
    assert_not_respond_to activity.production_detail, :notes
    assert_not_respond_to activity.production_detail, :pending_confirmations
    assert_not_respond_to activity.production_detail, :save
    assert_equal technical_attributes.merge("media_files" => nil).symbolize_keys, activity.production_detail.to_h
    assert_kind_of Data, activity.production_detail
    assert_predicate activity.production_detail, :frozen?
    assert_raises(FrozenError) { activity.production_detail.instance_variable_set(:@audio, "Changed audio") }
    assert_equal record.attributes, record.reload.attributes
  end

  test "returns no production information when an act has no production record" do
    activity = Activity.find(1)

    assert_nil activity.executors
    assert_nil activity.notes
    assert_nil activity.pending_confirmations
    assert_nil activity.production_detail
  end

  test "fresh activities reflect existing production edits and deletions" do
    record = ProductionDetail.create!(schedule_entry_id: 1, executors: "Initial team", notes: "Initial notes", audio: "Initial audio")
    assert_equal "Initial team", Activity.find(1).executors

    record.update!(executors: "Updated team", notes: "Updated notes", audio: "Updated audio")
    activity = Activity.find(1)
    assert_equal "Updated team", activity.executors
    assert_equal "Updated notes", activity.notes
    assert_equal "Updated audio", activity.production_detail.audio

    record.destroy!
    activity = Activity.find(1)
    assert_nil activity.executors
    assert_nil activity.notes
    assert_nil activity.production_detail
  end

  test "reads imported operation details without using production records with matching IDs" do
    operation = Activity.find_operation_by_source_id(8)
    ProductionDetail.create!(schedule_entry_id: operation.id, executors: "Unrelated team", audio: "Unrelated audio", notes: "Unrelated notes")
    ProductionDetail.create!(schedule_entry_id: operation.source_id, executors: "Act team", audio: "Act audio", notes: "Act notes")
    expected = operation.details.deep_dup

    assert_no_difference "ProductionDetail.count" do
      assert_equal expected.fetch("executors"), operation.executors
      assert_nil operation.notes
      assert_nil operation.pending_confirmations
      assert_instance_of ProductionInformation, operation.production_detail
      assert_equal expected.symbolize_keys.slice(*ProductionInformation.members), operation.production_detail.to_h
      assert_equal "Prueba de sonido 7:20 am", operation.production_detail.audio
      assert_not_respond_to operation.production_detail, :save
    end
    assert_equal expected, operation.details
  end

  test "keeps operation notes questions and pending wording outside technical information" do
    attributes = Activity.operations.first.details.merge(
      "notes" => "General notes\nSecond line",
      "pending_confirmations" => "Confirm the team",
      "general_questions" => "Who coordinates?",
      "media_files" => "Required playlist"
    )
    activity = Activity.new(
      "id" => 100, "kind" => "operation", "title" => "Example operation", "day" => "Domingo 15",
      "start_time" => nil, "end_time" => nil, "duration" => nil, "commissions" => [], "details" => attributes
    )

    assert_equal "General notes\nSecond line", activity.notes
    assert_equal "Confirm the team", activity.pending_confirmations
    assert_equal "Who coordinates?", activity.details.fetch("general_questions")
    assert_equal "Required playlist", activity.production_detail.media_files
    assert_not_respond_to activity.production_detail, :notes
    assert_not_respond_to activity.production_detail, :general_questions
    assert_not_respond_to activity.production_detail, :pending_confirmations
    assert_equal attributes, activity.details
  end
end

require "test_helper"

class ActivityImportTest < ActiveSupport::TestCase
  test "imports source attributes with stable IDs and original metadata" do
    Activity.delete_all

    assert_difference "Activity.count", 76 do
      Activity.import_from_source!
    end

    acts = YAML.safe_load_file(Rails.root.join("config/data/schedule.yml"))
    operations = YAML.safe_load_file(Rails.root.join("config/data/operational_activities.yml")).fetch("operational_activities")
    acts.each do |attributes|
      expected = attributes.except("activity").merge(
        "title" => attributes.fetch("activity"), "source_id" => attributes.fetch("id"), "kind" => "act", "phase" => "program"
      )
      assert_source_attributes expected
    end
    operations.each { |attributes| assert_source_attributes attributes.merge("kind" => "operation") }
    assert_equal (1..31).to_a, Activity.acts.pluck(:id)
    assert_equal (32..44).to_a, Activity.operations.pluck(:id)
    assert_equal (45..76).to_a, Activity.preparation_actions.order(:id).pluck(:id)
    preparations = YAML.safe_load_file(Rails.root.join("config/data/preparations.yml")).fetch("preparations")
    preparations.each do |preparation|
      preparation.fetch("actions").each_with_index do |attributes, index|
        action = Activity.find(attributes.fetch("id"))
        assert_equal "preparation_action", action.kind
        assert_equal attributes.fetch("id"), action.source_id
        assert_equal preparation.fetch("id"), action.preparation_id
        assert_equal index + 1, action.position
        assert_equal preparation.fetch("day"), action.day
        assert_equal preparation.fetch("phase", "program"), action.phase
        assert_equal preparation.fetch("source_sheet"), action.source_sheet
        assert_equal attributes.fetch("source_row"), action.source_row
        assert_equal attributes.fetch("description"), action.title
        assert_equal attributes.slice("start_time", "end_time", "duration"), action.attributes.slice("start_time", "end_time", "duration")
        assert_equal attributes.except("id", "source_row", "start_time", "end_time", "duration", "description"), action.details
        commission = attributes["commission"]
        expected_commissions = commission.present? && !commission.include?("?") ? [ commission ] : []
        assert_equal expected_commissions, action.commissions
      end
    end
    assert_equal "Por definir con la Arena", Activity.find(38).start_time
    assert_nil Activity.find(32).start_time
  end

  test "repeated imports restore only missing activities and preserve edits" do
    act = Activity.find(1)
    operation = Activity.find(32)
    action = Activity.find(45)
    action.update!(title: "Edited preparation action", details: action.details.merge("notes" => "Edited action notes"))
    expected_action = action.reload.attributes
    act.update!(title: "Edited act", start_time: "Por confirmar", commissions: [ "New team" ])
    operation.update!(details: operation.details.merge("notes" => "Edited operation notes"))
    expected_act = act.reload.attributes
    expected_operation = operation.reload.attributes
    Activity.find(44).destroy!

    assert_difference "Activity.count", 1 do
      Activity.import_from_source!
    end
    assert_no_difference "Activity.count" do
      Activity.import_from_source!
    end

    assert_equal expected_act, act.reload.attributes
    assert_equal expected_operation, operation.reload.attributes
    assert_equal expected_action, action.reload.attributes
    assert_equal 13, Activity.find(44).source_id
  end

  test "imports only preparation actions when upgrading an existing activity database" do
    expected_records = Activity.where.not(kind: "preparation_action").order(:id).map(&:attributes)
    Activity.preparation_actions.delete_all

    assert_difference "Activity.count", 32 do
      Activity.import_from_source!
    end

    assert_equal expected_records, Activity.where.not(kind: "preparation_action").order(:id).map(&:attributes)
    assert_equal [ 48, 49 ], Preparation.find(2).actions.map(&:id)
  end

  test "rolls back the import when an action position conflicts with an existing record" do
    Activity.preparation_actions.delete_all
    Activity.create!(
      id: 100, kind: "preparation_action", source_id: 100, title: "Existing action", day: "Domingo 15",
      preparation_id: 2, position: 2
    )

    assert_raises(ActiveRecord::RecordInvalid) { Activity.import_from_source! }

    assert_equal [ 100 ], Activity.preparation_actions.pluck(:id)
    assert_equal 44, Activity.where.not(kind: "preparation_action").count
  end

  test "does not modify production questions documents or attachments during import" do
    production = ProductionDetail.create!(schedule_entry_id: 1, executors: "Manually assigned team", notes: "Manual notes")
    question = Question.create!(schedule_entry_id: 1, body: "Manual question", answer: "Manual answer")
    document = Document.create!(
      schedule_entry_id: 1,
      file: { io: StringIO.new("Manual document"), filename: "manual.txt", content_type: "text/plain" }
    )
    expected_production = production.attributes
    expected_question = question.attributes
    expected_document = document.reload.attributes
    attachment_id = document.file.attachment.id
    Activity.delete_all

    assert_no_difference [ "ProductionDetail.count", "Question.count", "Document.count", "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ] do
      Activity.import_from_source!
    end

    assert_equal expected_production, production.reload.attributes
    assert_equal expected_question, question.reload.attributes
    assert_equal expected_document, document.reload.attributes
    assert_equal attachment_id, document.file.attachment.id
    assert_equal "Manual document", document.file.download
    assert_equal "Manually assigned team", Activity.find(1).executors
    assert_equal 1, question.activity.id
  end

  test "rolls back the import if a source identity conflicts with an existing record" do
    Activity.delete_all
    Activity.create!(id: 100, kind: "operation", source_id: 13, title: "Existing operation", day: "Domingo 15")

    assert_raises(ActiveRecord::RecordInvalid) { Activity.import_from_source! }

    assert_equal [ 100 ], Activity.pluck(:id)
    assert_equal "Existing operation", Activity.find(100).title
  end

  test "validates the minimum persisted identity and schedule attributes" do
    activity = Activity.new(title: "", day: "", kind: "unknown", phase: "unknown")

    assert_not activity.valid?
    assert activity.errors.of_kind?(:title, :blank)
    assert activity.errors.of_kind?(:day, :blank)
    assert activity.errors.of_kind?(:source_id, :blank)
    assert activity.errors.of_kind?(:kind, :inclusion)
    assert activity.errors.of_kind?(:phase, :inclusion)

    duplicate = Activity.find(32).dup
    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:source_id, :taken)
  end

  private

  def assert_source_attributes(attributes)
    activity = Activity.find(attributes.fetch("id"))
    attributes.each do |attribute, value|
      if value.nil?
        assert_nil activity.public_send(attribute)
      else
        assert_equal value, activity.public_send(attribute)
      end
    end
  end
end

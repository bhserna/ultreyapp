require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "selects persisted acts in ID order without including other activity kinds" do
    act = Activity.create!(kind: "act", source_id: 100, title: "Additional act", day: "Lunes 16")
    entries = Activity.acts.to_a

    assert_includes entries, act
    assert entries.all?(&:persisted?)
    assert entries.all? { |entry| entry.kind == "act" }
    assert_equal entries.map(&:id).sort, entries.map(&:id)
    assert_not_includes entries, activities(:activity_32)
    assert_not_includes entries, activities(:activity_48)
  end

  test "preserves integer and subact numbering along with source metadata" do
    act = activities(:activity_1)
    subact = activities(:activity_10)

    assert_equal 1, act.reload.act_number
    assert_equal "7.4", subact.reload.act_number
    assert_equal "1er, día 15 Nov", act.source_sheet
    assert_equal 29, act.source_row
    assert_equal "INICIO / Proyección Video Inicio “Ultreyas Monterrey 1998–2026”", act.title
    assert_equal "10:00", act.start_time
    assert_equal "10:05", act.end_time
    assert_equal "0:05", act.duration
  end

  test "gives all activity kinds unique explicit IDs without renumbering existing acts" do
    activities = Activity.all

    assert_equal 76, activities.size
    assert_equal activities.size, activities.map(&:id).uniq.size
    assert activities.all? { |activity| activity.instance_of?(Activity) }
    assert_equal (1..31).to_a, Activity.acts.map(&:id)
    assert_equal (32..44).to_a, Activity.operations.map(&:id)
    assert_equal (45..76).to_a, Activity.preparation_actions.order(:id).map(&:id)
    assert_equal (1..13).to_a, Activity.operations.map(&:source_id)
    assert_equal "act", Activity.find(1).kind
    assert_equal "operation", Activity.find("32").kind
    assert_equal "Recepción de Diócesis", Activity.find(32).title
    assert_equal "Recepción de Diócesis", Activity.find_operation_by_source_id("1").title
    assert_nil Activity.find(32).act_number
    assert_raises(ActiveRecord::RecordNotFound) { Activity.acts.find(32) }
    assert_raises(ActiveRecord::RecordNotFound) { Activity.find_operation_by_source_id(32) }
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

  test "finds acts with stable numeric or route IDs and rejects unknown IDs" do
    assert_equal Activity.find(1).title, Activity.find("1").title
    assert_equal 1, Activity.find("1").id
    assert_equal "program", Activity.find(1).phase
    assert_raises(ActiveRecord::RecordNotFound) { Activity.find(999) }
  end

  test "question references resolve to the activity model" do
    question = Question.create!(schedule_entry_id: 3, body: "Who coordinates this act?")

    assert_instance_of Activity, question.activity
    assert_equal 3, question.activity.id
    assert_equal Activity.find(3).title, question.activity.title
    assert_nil Question.new(body: "General question").activity
  end
end

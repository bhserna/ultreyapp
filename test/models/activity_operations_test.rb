require "test_helper"

class ActivityOperationsTest < ActiveSupport::TestCase
  test "selects persisted operations in ID order without including acts or preparation actions" do
    operation = Activity.create!(kind: "operation", source_id: 100, title: "Additional operation", day: "Sábado 14")
    operations = Activity.operations.to_a

    assert_includes operations, operation
    assert operations.all? { |activity| activity.kind == "operation" }
    assert_equal operations.map(&:id).sort, operations.map(&:id)
    assert_not_includes operations, activities(:activity_1)
    assert_not_includes operations, activities(:activity_48)
    assert_equal [ "AC", "Hosp" ], activities(:activity_32).commissions
  end

  test "retains unknown times questions and technical requirements without inventing missing data" do
    assert_nil Activity.find(32).start_time
    assert_equal "01:30", Activity.find(34).start_time
    assert_equal "08:00", Activity.find(34).end_time
    assert_equal "6:30", Activity.find(34).duration
    assert_equal "Por definir con la Arena", Activity.find(38).start_time
    assert_equal "Por definir", Activity.find(43).end_time
    assert_equal "Lydia", Activity.find(34).details.fetch("executors")
    assert_includes Activity.find(39).details.fetch("requirements"), "6 micrófonos de voz"
    assert_includes Activity.find(42).details.fetch("general_questions"), "Con qué laptop"
    assert_includes Activity.find(42).details.fetch("notes"), "ANetwork solo proporciona"
    assert_equal [ "EyA" ], Activity.find(41).commissions
  end

  test "finds operations by their original route IDs independently of act IDs" do
    operation = Activity.find_operation_by_source_id("1")

    assert_equal "Recepción de Diócesis", operation.title
    assert_equal 32, operation.id
    assert_equal 1, operation.source_id
    assert_equal "act", Activity.find(1).kind
    assert_raises(ActiveRecord::RecordNotFound) { Activity.find_operation_by_source_id(999) }
  end
end

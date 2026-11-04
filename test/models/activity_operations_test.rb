require "test_helper"

class ActivityOperationsTest < ActiveSupport::TestCase
  test "includes only the operational source rows before preparations and excludes the closing marker" do
    source = YAML.safe_load_file(Rails.root.join("config/data/operational_activities.yml"))
    activities = Activity.operations

    assert_equal (32..44).to_a, activities.map(&:id)
    assert_equal (1..13).to_a, activities.map(&:source_id)
    assert activities.all? { |activity| activity.kind == "operation" }
    assert_equal [ 3, 4, *(7..17) ], source.fetch("operational_activities").map { |activity| activity.fetch("source_row") }
    assert_equal [ "Sábado 14", "Sábado 14" ] + [ "Domingo 15" ] * 11, activities.map(&:day)
    assert_equal [ "Recepción y atención a participantes", "Montaje e instalaciones", "Preparación técnica", "Servicios y proveedores" ], activities.map(&:category).uniq
    assert activities.none? { |activity| activity.title.include?("Se finalizan") }
    assert_equal [ "AC", "Hosp" ], activities.first.commissions

    source.fetch("operational_activities").zip(activities).each do |attributes, activity|
      assert_equal attributes.fetch("title"), activity.title
      assert_equal attributes.fetch("details"), activity.details
      assert_equal attributes.fetch("commissions"), activity.commissions
    end
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
    assert_empty Activity.find(41).commissions
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

require "test_helper"

class OperationalActivityTest < ActiveSupport::TestCase
  test "includes only the operational source rows before preparations and excludes the closing marker" do
    source = YAML.safe_load_file(Rails.root.join("config/data/operational_activities.yml"))
    activities = OperationalActivity.all

    assert_equal (1..13).to_a, activities.map(&:id)
    assert_equal [3, 4, *(7..17)], source.fetch("operational_activities").map { |activity| activity.fetch("source_row") }
    assert_equal ["Sábado 14", "Sábado 14"] + ["Domingo 15"] * 11, activities.map(&:day)
    assert_equal ["Recepción y atención a participantes", "Montaje e instalaciones", "Preparación técnica", "Servicios y proveedores"], activities.map(&:category).uniq
    assert activities.none? { |activity| activity.title.include?("Se finalizan") }
    assert_equal ["AC", "Hosp"], activities.first.commissions
  end

  test "retains unknown times questions and technical requirements without inventing missing data" do
    assert_nil OperationalActivity.find(1).start_time
    assert_equal "01:30", OperationalActivity.find(3).start_time
    assert_equal "08:00", OperationalActivity.find(3).end_time
    assert_equal "6:30", OperationalActivity.find(3).duration
    assert_equal "Por definir con la Arena", OperationalActivity.find(7).start_time
    assert_equal "Por definir", OperationalActivity.find(12).end_time
    assert_equal "Lydia", OperationalActivity.find(3).details.fetch("executors")
    assert_includes OperationalActivity.find(8).details.fetch("requirements"), "6 micrófonos de voz"
    assert_includes OperationalActivity.find(11).details.fetch("general_questions"), "Con qué laptop"
    assert_includes OperationalActivity.find(11).details.fetch("notes"), "ANetwork solo proporciona"
    assert_empty OperationalActivity.find(10).commissions
  end

  test "finds operations by their own route IDs" do
    assert_equal "Recepción de Diócesis", OperationalActivity.find("1").title
    assert_raises(ActiveRecord::RecordNotFound) { OperationalActivity.find(999) }
  end
end

require "test_helper"

class PreparationTest < ActiveSupport::TestCase
  test "loads blue headers and nonempty light-blue action rows within the agreed range" do
    source = YAML.safe_load_file(Rails.root.join("config/data/preparations.yml"))
    preparations = Preparation.all

    assert_equal 17, preparations.size
    assert_equal 23, preparations.sum { |preparation| preparation.actions.size }
    assert_equal [19, 26, 32, 37, 43, 45, 51, 56, 62, 66, 69, 73, 78, 82, 86, 90, 94],
      source.fetch("preparations").map { |preparation| preparation.fetch("source_row") }
    assert preparations.flat_map(&:actions).all? { |action| action.fetch("description").present? }
    assert_not_includes preparations.flat_map(&:actions).map { |action| action.fetch("source_row") }, 38
    assert_empty preparations.first.schedule_entry_ids
    preparations.flat_map(&:schedule_entry_ids).each { |id| assert ScheduleEntry.find(id) }
  end

  test "preserves undecided start times without treating questions as commissions" do
    preparation = Preparation.new(
      "id" => 100, "title" => "Sin horario", "day" => "Domingo 15", "start_time" => nil,
      "schedule_entry_ids" => [],
      "actions" => [
        { "start_time" => "Por definir", "commission" => "¿Quién lo prepara?" },
        { "start_time" => nil, "commission" => nil }
      ]
    )
    assert_nil preparation.start_time
    assert_empty preparation.commissions
    assert_equal "Por definir con Programa", Preparation.all.first.start_time
  end

  test "finds preparations by route ID and preserves shared act references" do
    assert_equal [1, 2], Preparation.find("2").schedule_entry_ids
    assert_equal [7, 8, 9, 10], Preparation.find(7).schedule_entry_ids
    assert_equal [16], Preparation.find(13).schedule_entry_ids
    assert_equal [20], Preparation.find(17).schedule_entry_ids
    assert_raises(ActiveRecord::RecordNotFound) { Preparation.find(999) }
  end

  test "uses the first action start time and keeps the header when the action has none" do
    Preparation.all.each do |item|
      first_start = item.actions.first.fetch("start_time")
      assert_equal first_start, item.start_time if first_start.present?
    end
    preparation = Preparation.find(7)
    assert_equal "12:30", preparation.start_time
    assert_equal "12:30", preparation.actions.first.fetch("start_time")
    assert_equal "12:45", preparation.actions.first.fetch("end_time")

    furniture = Preparation.find(3).actions.last
    assert_equal "10:00", furniture.fetch("start_time")
    assert_equal "10:20", furniture.fetch("end_time")
    assert_equal "1-2 min", furniture.fetch("duration")

    next_day = Preparation.find(17)
    assert_equal "Domingo 15", next_day.day
    assert_equal "19:00", next_day.start_time
    assert_nil next_day.actions.first.fetch("start_time")
    assert_includes next_day.actions.first.fetch("description"), "2 reclinatorios"
  end
end

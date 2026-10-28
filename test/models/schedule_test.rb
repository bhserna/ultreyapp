require "test_helper"

class ScheduleModelTest < ActiveSupport::TestCase
  test "lists operational days and commissions while defaulting to the first program day" do
    schedule = Schedule.new(day: nil, commission: nil)

    assert_equal ["Sábado 14", "Domingo 15", "Lunes 16"], schedule.days
    assert_equal ["AC", "EyA", "Hosp", "Liturgia", "Marketing", "Programa", "Todas las comisiones"], schedule.commissions
    assert_equal "Domingo 15", schedule.selected_day
    assert_nil schedule.selected_commission
    assert_equal (1..19).to_a, schedule.entries.map(&:id)
  end

  test "ignores unknown days and commissions" do
    schedule = Schedule.new(day: "Unknown day", commission: "Unknown commission")

    assert_equal "Domingo 15", schedule.selected_day
    assert_nil schedule.selected_commission
    assert_equal (1..19).to_a, schedule.entries.map(&:id)
  end

  test "interleaves preparations and acts by start time without duplicating shared preparations" do
    schedule = Schedule.new(day: "Domingo 15", commission: nil)
    rows = schedule.rows

    assert_equal 47, rows.size
    assert_equal 17, rows.count { |row| row.is_a?(Preparation) }
    assert_equal 11, rows.grep(OperationalActivity).size
    timed_rows = rows.select { |row| row.start_time.to_s.match?(/\A\d{2}:\d{2}\z/) }
    assert_equal timed_rows.map(&:start_time).sort, timed_rows.map(&:start_time)
    assert_equal 1, rows.count { |row| row.is_a?(Preparation) && row.id == 2 }
    assert_equal "01:30", rows.first.start_time
    assert_equal "19:00", timed_rows.last.start_time
    assert_equal 4, rows.drop(timed_rows.size).size
    assert_equal "Por definir con Programa", rows.last.start_time
    assert_equal "12:30", rows.find { |row| row.is_a?(Preparation) && row.id == 7 }.start_time
    assert_equal "16:50", rows.find { |row| row.is_a?(Preparation) && row.id == 12 }.start_time

    monday = Schedule.new(day: "Lunes 16", commission: nil)
    assert_equal (20..31).to_a, monday.rows.grep(ScheduleEntry).map(&:id)
    assert_equal 9, monday.rows.grep(Preparation).size
    assert_equal "07:40", monday.rows.first.start_time
    assert_equal 18, monday.rows.first.id
    assert_equal "21:30", monday.rows.last.start_time
    assert_equal 20, monday.rows.last.id
  end

  test "filters preparations by their own commission and day" do
    schedule = Schedule.new(day: "Domingo 15", commission: "EyA")

    assert_equal [2, 3, 5, 6], schedule.rows.grep(Preparation).map(&:id)
    assert_equal [5], schedule.rows.grep(ScheduleEntry).map(&:id)
    assert_equal [9, 11, 8, 7], schedule.rows.grep(OperationalActivity).map(&:id)
    assert_empty Schedule.new(day: "Lunes 16", commission: "EyA").rows
  end

  test "combines row type day and commission filters" do
    operations = Schedule.new(day: "Domingo 15", commission: "Liturgia", row_type: "operations")
    assert_equal [5, 4, 6], operations.rows.map(&:id)
    assert operations.rows.all? { |row| row.is_a?(OperationalActivity) }
    assert_equal "operations", operations.selected_row_type

    saturday = Schedule.new(day: "Sábado 14", commission: "AC", row_type: "operations")
    assert_equal [1, 2], saturday.rows.map(&:id)
    assert_empty Schedule.new(day: "Sábado 14", commission: nil, row_type: "acts").rows
    assert_empty Schedule.new(day: "Sábado 14", commission: nil, row_type: "preparations").rows
    assert_equal 19, Schedule.new(day: "Domingo 15", commission: nil, row_type: "acts").rows.size
    assert_equal 17, Schedule.new(day: "Domingo 15", commission: nil, row_type: "preparations").rows.size

    unknown = Schedule.new(day: "Sábado 14", commission: nil, row_type: "unknown")
    assert_nil unknown.selected_row_type
    assert_equal [1, 2], unknown.rows.map(&:id)
  end

  test "filters entries by day and commission" do
    schedule = Schedule.new(day: "Domingo 15", commission: "EyA")

    assert_equal "Domingo 15", schedule.selected_day
    assert_equal "EyA", schedule.selected_commission
    assert_equal [5], schedule.entries.map(&:id)
  end

  test "keeps a valid commission even when it has no entries on the selected day" do
    schedule = Schedule.new(day: "Lunes 16", commission: "EyA")

    assert_equal "EyA", schedule.selected_commission
    assert_empty schedule.entries
  end
end

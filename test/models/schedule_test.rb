require "test_helper"

class ScheduleModelTest < ActiveSupport::TestCase
  test "lists available days and commissions and defaults to the first day" do
    schedule = Schedule.new(day: nil, commission: nil)

    assert_equal ["Domingo 15", "Lunes 16"], schedule.days
    assert_equal ScheduleEntry.all.flat_map(&:commissions).uniq.sort, schedule.commissions
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

    assert_equal 36, rows.size
    assert_equal 17, rows.count { |row| row.is_a?(Preparation) }
    assert_equal rows.map(&:start_time).sort, rows.map(&:start_time)
    assert_equal 1, rows.count { |row| row.is_a?(Preparation) && row.id == 2 }
    assert_equal "09:45", rows.first.start_time
    assert_equal "19:00", rows[-2].start_time
    assert_equal "Por definir con Programa", rows.last.start_time
    assert_equal "12:30", rows.find { |row| row.is_a?(Preparation) && row.id == 7 }.start_time
    assert_equal "16:50", rows.find { |row| row.is_a?(Preparation) && row.id == 12 }.start_time

    monday = Schedule.new(day: "Lunes 16", commission: nil)
    assert_equal (20..31).to_a, monday.rows.map(&:id)
    assert monday.rows.all? { |row| row.is_a?(ScheduleEntry) }
  end

  test "filters preparations by their own commission and day" do
    schedule = Schedule.new(day: "Domingo 15", commission: "EyA")

    assert_equal [2, 3, 5, 6], schedule.rows.grep(Preparation).map(&:id)
    assert_equal [5], schedule.rows.grep(ScheduleEntry).map(&:id)
    assert_empty Schedule.new(day: "Lunes 16", commission: "EyA").rows
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

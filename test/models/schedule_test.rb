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

  test "filters entries by day and commission" do
    schedule = Schedule.new(day: "Domingo 15", commission: "EyA")

    assert_equal "Domingo 15", schedule.selected_day
    assert_equal "EyA", schedule.selected_commission
    assert_equal [5], schedule.entries.map(&:id)
    assert_equal [5], schedule.resource_counts.keys
  end

  test "keeps a valid commission even when it has no entries on the selected day" do
    schedule = Schedule.new(day: "Lunes 16", commission: "EyA")

    assert_equal "EyA", schedule.selected_commission
    assert_empty schedule.entries
    assert_empty schedule.resource_counts
  end
end

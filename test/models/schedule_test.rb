require "test_helper"

class ScheduleModelTest < ActiveSupport::TestCase
  test "list available days" do
    activities(:reception).update!(day: "Día previo")
    preparations(:next_day_setup).update!(day: "Día posterior")
    expected = [ "Día previo", activities(:opening_act).day, activities(:next_day_act).day, "Día posterior" ]

    assert_equal expected.sort, Schedule.new(day: nil, commission: nil).days.sort
  end

  test "list available commissions" do
    activities(:chair_setup).update!(commissions: [ "Equipo de preparación", "Programa" ])

    assert_equal [ "Equipo de preparación", "EyA", "Hosp", "Liturgia", "Programa" ], Schedule.new(day: nil, commission: nil).commissions
  end

  test "select a default day" do
    activities(:reception).update!(day: "Día previo")

    assert_equal activities(:opening_act).day, Schedule.new(day: nil, commission: nil).selected_day
  end

  test "ignore unknown filters" do
    schedule = Schedule.new(day: "Unknown day", commission: "Unknown commission", row_type: "unknown")
    default = Schedule.new(day: nil, commission: nil)

    assert_equal default.selected_day, schedule.selected_day
    assert_nil schedule.selected_commission
    assert_nil schedule.selected_row_type
    assert_equal default.rows, schedule.rows
  end

  test "combine day, type and commission filters" do
    operation = activities(:sound_check)
    activities(:next_day_operation).update!(commissions: operation.commissions)

    schedule = Schedule.new(day: operation.day, commission: "EyA", row_type: "operations")

    assert_equal [ operation ], schedule.rows
  end

  test "keep a commission with no results" do
    schedule = Schedule.new(day: activities(:next_day_act).day, commission: "EyA")

    assert_equal "EyA", schedule.selected_commission
    assert_empty schedule.rows
  end

  test "order by phase" do
    operation = activities(:reception)
    preparation_work = activities(:sound_check)
    program_work = activities(:next_day_operation)
    operation.update!(phase: "pre_event", start_time: "23:00")
    preparation_work.update!(phase: "before_parade", start_time: "12:00")
    program_work.update!(day: operation.day, phase: "program", start_time: "01:00")

    schedule = Schedule.new(day: operation.day, commission: nil, row_type: "operations")

    assert_equal [ operation, preparation_work, program_work ], schedule.rows
  end

  test "order by start time" do
    first = activities(:closing_act)
    second = activities(:opening_act)
    first.update!(start_time: "09:00")
    second.update!(start_time: "11:00")

    schedule = Schedule.new(day: first.day, commission: nil, row_type: "acts")

    assert_equal [ first, second ], schedule.rows
  end

  test "fall back to end time for ordering" do
    operation = activities(:reception)
    earlier_operation = activities(:sound_check)

    [ nil, "Por confirmar" ].each do |start_time|
      operation.update!(start_time: start_time, end_time: "08:30")
      schedule = Schedule.new(day: operation.day, commission: nil, row_type: "operations")

      assert_equal [ earlier_operation, operation ], schedule.rows
      assert_equal [ start_time, "08:30" ], operation.reload.attributes.values_at("start_time", "end_time")
    end
  end

  test "place unknown times last within their phase" do
    unknown = activities(:reception)
    timed = activities(:sound_check)
    next_phase = activities(:next_day_operation)
    unknown.update!(start_time: "Por confirmar", end_time: nil)
    next_phase.update!(day: unknown.day, phase: "program", start_time: "01:00")

    schedule = Schedule.new(day: unknown.day, commission: nil, row_type: "operations")

    assert_equal [ timed, unknown, next_phase ], schedule.rows
  end

  test "exclude preparation action rows" do
    preparation = preparations(:opening_setup)
    rows = Schedule.new(day: preparation.day, commission: nil).rows

    assert_equal 1, rows.count(preparation)
    assert_not_includes rows, activities(:chair_setup)
    assert_not_includes rows, activities(:microphone_setup)
  end
end

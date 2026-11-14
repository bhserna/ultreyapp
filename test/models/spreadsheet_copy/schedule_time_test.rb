require "test_helper"

class SpreadsheetCopy::ScheduleTimeTest < ActiveSupport::TestCase
  test "preserve trimmed text and order ranges by their start time" do
    schedule = SpreadsheetCopy::ScheduleTime.new(" 10:05–10:20 ")

    assert_equal "10:05–10:20", schedule.to_s
    assert_equal 605, schedule.start_minutes
  end

  test "interpret 24 hour times and both common range separators" do
    { "00:00" => 0, "08:30" => 510, "13:00-14:00" => 780, "23:59" => 1439 }.each do |value, expected|
      assert_equal expected, SpreadsheetCopy::ScheduleTime.new(value).start_minutes
    end
  end

  test "interpret AM and PM including midnight and noon without changing their display" do
    { "09:45 am" => 585, "01:30 pm" => 810, "12:00 am" => 0, "12:00 PM" => 720 }.each do |value, expected|
      schedule = SpreadsheetCopy::ScheduleTime.new(value)

      assert_equal value, schedule.to_s
      assert_equal expected, schedule.start_minutes
    end
  end

  test "convert Excel time values in seconds since midnight" do
    {
      0 => [ "00:00", 0 ],
      27_000 => [ "07:30", 450 ],
      43_200 => [ "12:00", 720 ],
      86_340 => [ "23:59", 1439 ]
    }.each do |value, (text, minutes)|
      schedule = SpreadsheetCopy::ScheduleTime.new(value)

      assert_equal text, schedule.to_s
      assert_equal minutes, schedule.start_minutes
    end
  end

  test "keep free text and leave empty values without a sortable time" do
    [ nil, "", "  ", "Por confirmar", "Antes de abrir puertas" ].each do |value|
      schedule = SpreadsheetCopy::ScheduleTime.new(value)

      assert_equal value.to_s.strip, schedule.to_s
      assert_nil schedule.start_minutes
    end
  end

  test "invalid times are preserved but not used for ordering" do
    [ "24:00", "08:60", "10:555", "00:30 am", "13:00 pm", -1, 86_400 ].each do |value|
      schedule = SpreadsheetCopy::ScheduleTime.new(value)

      assert_equal value.to_s, schedule.to_s
      assert_nil schedule.start_minutes
    end
  end
end

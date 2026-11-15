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

  test "display AM and PM including midnight and noon in 24 hour format" do
    { "09:45 am" => 585, "01:30 pm" => 810, "12:00 am" => 0, "12:00 PM" => 720 }.each do |value, expected|
      schedule = SpreadsheetCopy::ScheduleTime.new(value)

      assert_equal format("%02d:%02d", expected / 60, expected % 60), schedule.to_s
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

  test "interpret ambiguous hours as afternoon when the sheet has passed noon" do
    { "1:09–1:19" => 789, "2:00–3:50" => 840, 7200 => 840 }.each do |value, expected|
      schedule = SpreadsheetCopy::ScheduleTime.new(value, after_noon: true)

      assert_equal expected, schedule.start_minutes
      assert_equal({ "1:09–1:19" => "13:09–13:19", "2:00–3:50" => "14:00–15:50", 7200 => "14:00" }.fetch(value), schedule.to_s)
    end
  end

  test "the afternoon context respects explicit AM PM and 24 hour values" do
    { "09:45 am" => 585, "12:00 am" => 0, "01:30 pm" => 810, "12:00" => 720, "14:00" => 840 }.each do |value, expected|
      assert_equal expected, SpreadsheetCopy::ScheduleTime.new(value, after_noon: true).start_minutes
    end
    assert_nil SpreadsheetCopy::ScheduleTime.new("Por confirmar", after_noon: true).start_minutes
  end

  test "keep free text and leave empty values without a sortable time" do
    [ nil, "", "  ", "Por confirmar", "Antes de abrir puertas" ].each do |value|
      schedule = SpreadsheetCopy::ScheduleTime.new(value)

      assert_equal value.to_s.strip, schedule.to_s
      assert_nil schedule.start_minutes
    end
  end

  test "format ranges and preserve annotations" do
    {
      "3:00–08:00 am" => "03:00–08:00",
      "1:30 - 2:45 PM" => "13:30-14:45",
      "11:00 am–1:00 pm" => "11:00–13:00",
      "9:05 (aproximado)" => "09:05 (aproximado)",
      "9:05 pm llegada" => "21:05 llegada",
      "09:00–10:75" => "09:00–10:75"
    }.each do |value, expected|
      assert_equal expected, SpreadsheetCopy::ScheduleTime.new(value).to_s
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

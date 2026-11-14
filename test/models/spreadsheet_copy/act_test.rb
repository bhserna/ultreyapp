require "test_helper"

class SpreadsheetCopy::ActTest < ActiveSupport::TestCase
  test "use the position within its day as the URL parameter rather than the act number" do
    act = SpreadsheetCopy::Act.new(day: "Domingo 15", position: 3, schedule: "10:00", number: 1, title: "Inicio")

    assert_equal "3", act.to_param
  end

  test "an unnumbered activity also has a URL parameter" do
    act = SpreadsheetCopy::Act.new(day: "Domingo 15", position: 1, schedule: "08:30", number: nil, title: "Entrada")

    assert_equal "1", act.to_param
  end
end

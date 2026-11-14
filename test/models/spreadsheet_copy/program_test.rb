require "test_helper"

class SpreadsheetCopy::ProgramTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  test "read program sheets in order and ignore preparation sheets" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    acts = copy.program.acts
    sunday = acts.select { |act| act.day == "Domingo 15" }

    assert_equal [ "Domingo 15" ] * 4 + [ "Lunes 16" ] * 2, acts.map(&:day)
    assert_equal [ "Entrada a la Arena", "Inicio / Video", "Grupo Folklórico", "Sin horario todavía" ], sunday.map(&:title)
    assert_equal [ nil, "1", "2", nil ], sunday.map(&:number)
    assert_equal "08:30–09:30", sunday.first.schedule
    assert_equal "", sunday.last.schedule
  end

  test "match columns by header rather than position and preserve text act numbers" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    monday = copy.program.acts.select { |act| act.day == "Lunes 16" }

    assert_equal "Bienvenida del lunes", monday.first.title
    assert_equal "08:00–08:15", monday.first.schedule
    assert_equal "1", monday.first.number
    assert_equal "02A", monday.last.number
  end

  test "report an unreadable saved copy without changing it" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    original = copy.file.download

    assert_raises SpreadsheetCopy::Program::ReadError do
      copy.program.acts
    end

    assert_equal original, copy.file.download
  end
end

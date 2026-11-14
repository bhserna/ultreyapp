require "test_helper"

class SpreadsheetCopy::ReaderTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "read every sheet as rows keyed by source headers without interpreting values" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    sheets = SpreadsheetCopy::Reader.new(copy).read

    assert_equal [ "Domingo 15", "Preparaciones Dom 15", "Lunes 16" ], sheets.keys
    assert_equal [
      { "Horario" => "08:30–09:30", "# Acto" => nil, "Actividad" => "Entrada a la Arena", "Audio" => nil },
      { "Horario" => "10:00–10:05", "# Acto" => 1, "Actividad" => "Inicio / Video", "Audio" => nil },
      { "Horario" => "10:05–10:20", "# Acto" => 2, "Actividad" => "Grupo Folklórico", "Audio" => nil },
      { "Horario" => nil, "# Acto" => nil, "Actividad" => "Sin horario todavía", "Audio" => nil }
    ], sheets["Domingo 15"]
    assert_equal [
      { "Horario de Participación" => "09:45", "Previo al Acto #" => 2, "Nombre del Acto" => "Preparar instrumentos" }
    ], sheets["Preparaciones Dom 15"]
    assert_equal [
      { "Actividad" => "Bienvenida del lunes", "Horario" => "08:00–08:15", "# Acto" => 1 },
      { "Actividad" => "Acto con identificador de texto", "Horario" => "08:15–08:30", "# Acto" => "02A" }
    ], sheets["Lunes 16"]
  end

  test "report an unreadable saved copy without changing it" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    original = copy.file.download

    assert_raises SpreadsheetCopy::Reader::ReadError do
      SpreadsheetCopy::Reader.new(copy).read
    end

    assert_equal original, copy.file.download
  end
end

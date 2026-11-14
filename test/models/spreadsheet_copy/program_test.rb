require "test_helper"

class SpreadsheetCopy::ProgramTest < ActiveSupport::TestCase
  test "build acts in sheet and row order with their day" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        { "Horario" => "08:30–09:30", "# Acto" => nil, "Actividad" => "Entrada a la Arena" },
        { "Horario" => "10:00–10:05", "# Acto" => 1.0, "Actividad" => "Inicio / Video" }
      ],
      "Preparaciones Dom 15" => [
        { "Horario de Participación" => "09:45", "Previo al Acto #" => 2, "Nombre del Acto" => "Preparar instrumentos" }
      ],
      "Lunes 16" => [
        { "Actividad" => "Bienvenida del lunes", "Horario" => "08:00–08:15", "# Acto" => "02A" }
      ]
    )

    acts = program.acts

    assert_equal [ "Domingo 15", "Domingo 15", "Lunes 16" ], acts.map(&:day)
    assert_equal [ "Entrada a la Arena", "Inicio / Video", "Bienvenida del lunes" ], acts.map(&:title)
    assert_equal [ nil, "1", "02A" ], acts.map(&:number)
    assert_equal [ "08:30–09:30", "10:00–10:05", "08:00–08:15" ], acts.map(&:schedule)
  end

  test "ignore rows without an activity and allow missing schedules and numbers" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        { "Horario" => "10:00", "# Acto" => 1, "Actividad" => nil },
        { "Horario" => "10:05", "# Acto" => 2, "Actividad" => "  " },
        { "Horario" => nil, "# Acto" => nil, "Actividad" => "  Sin horario todavía  " }
      ]
    )

    assert_equal 1, program.acts.size
    act = program.acts.first
    assert_equal "Sin horario todavía", act.title
    assert_equal "", act.schedule
    assert_nil act.number
  end

  test "report when no sheet has the program columns" do
    program = SpreadsheetCopy::Program.new(
      "Preparaciones" => [ { "Nombre del Acto" => "Preparar instrumentos" } ]
    )

    assert_raises SpreadsheetCopy::Program::ReadError do
      program.acts
    end
  end
end

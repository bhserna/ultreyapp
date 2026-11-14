require "test_helper"

class SpreadsheetCopy::ProgramTest < ActiveSupport::TestCase
  test "build acts in sheet and row order and keep positions when blank titles are skipped" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        { "Horario" => "08:30–09:30", "# Acto" => nil, "Actividad" => "Entrada a la Arena" },
        { "Actividad" => " " },
        { "Horario" => "10:00–10:05", "# Acto" => 1, "Actividad" => "Inicio / Video" }
      ],
      "Preparaciones Dom 15" => [
        { "Previo al Acto #" => 2, "Nombre del Acto" => "Preparar instrumentos" }
      ],
      "Lunes 16" => [
        { "Actividad" => "Bienvenida del lunes", "Horario" => "08:00–08:15", "# Acto" => 17 }
      ]
    )

    assert_equal [ "Domingo 15", "Lunes 16" ], program.days
    assert_equal [ "Entrada a la Arena", "Inicio / Video", "Bienvenida del lunes" ], program.acts.map(&:title)
    assert_equal [ [ "Domingo 15", 1 ], [ "Domingo 15", 3 ], [ "Lunes 16", 1 ] ], program.acts.map { |act| [ act.day, act.position ] }
  end

  test "match preparation sheets to program days and keep their row positions" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [ { "Horario" => "10:05", "# Acto" => 2, "Actividad" => "Grupo Folklórico" } ],
      "Lunes 16" => [ { "Horario" => "08:00", "# Acto" => 17, "Actividad" => "Apertura" } ],
      "Preparaciones Dom 15" => [
        { "Previo al Acto #" => nil, "Nombre del Acto" => "Instalación" },
        { "Nombre del Acto" => " " },
        { "Previo al Acto #" => 2, "Nombre del Acto" => "Preparar instrumentos" }
      ],
      "Preparaciones Lunes 16" => [
        { "Previo al Acto #" => 17, "Nombre del Acto" => "Preparar apertura" }
      ]
    )

    assert_equal [ "Instalación", "Preparar instrumentos", "Preparar apertura" ], program.preparations.map(&:title)
    assert_equal [ [ "Domingo 15", 1 ], [ "Domingo 15", 3 ], [ "Lunes 16", 1 ] ], program.preparations.map { |entry| [ entry.day, entry.position ] }
  end

  test "mix preparations and acts chronologically within a day with unknown times first" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        { "Horario" => "08:30–09:30", "# Acto" => nil, "Actividad" => "Entrada" },
        { "Horario" => "10:00–10:05", "# Acto" => 1, "Actividad" => "Inicio" },
        { "Horario" => "13:00–14:00", "# Acto" => 2, "Actividad" => "Acto de la tarde" }
      ],
      "Lunes 16" => [ { "Horario" => "08:00", "# Acto" => 3, "Actividad" => "Solo lunes" } ],
      "Preparaciones Dom 15" => [
        { "Horario de Preparación" => "09:45 am", "Previo al Acto #" => 1, "Nombre del Acto" => "Preparación matutina" },
        { "Horario de Preparación" => nil, "Previo al Acto #" => nil, "Nombre del Acto" => "Sin horario" },
        { "Horario de Preparación" => "Por confirmar", "Nombre del Acto" => "Horario pendiente" },
        { "Horario de Preparación" => "10:00", "Nombre del Acto" => "Preparación al inicio" },
        { "Horario de Preparación" => "12:00 pm", "Nombre del Acto" => "Preparación al mediodía" },
        { "Horario de Preparación" => "01:30 pm", "Nombre del Acto" => "Preparación vespertina" }
      ]
    )

    assert_equal [
      "Sin horario", "Horario pendiente", "Entrada", "Preparación matutina", "Preparación al inicio",
      "Inicio", "Preparación al mediodía", "Acto de la tarde", "Preparación vespertina"
    ], program.entries(day: "Domingo 15").map(&:title)
    assert_equal [ "Solo lunes" ], program.entries(day: "Lunes 16").map(&:title)
  end

  test "programs without preparation sheets still list their acts" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [ { "Horario" => "10:00", "# Acto" => 1, "Actividad" => "Inicio" } ]
    )

    assert_empty program.preparations
    assert_equal [ "Inicio" ], program.entries(day: "Domingo 15").map(&:title)
  end

  test "report preparation sheets that cannot be matched to a program day" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [ { "Horario" => "10:00", "# Acto" => 1, "Actividad" => "Inicio" } ],
      "Preparaciones Lunes 16" => [ { "Previo al Acto #" => 1, "Nombre del Acto" => "Montaje" } ]
    )

    assert_raises SpreadsheetCopy::Program::ReadError do
      program.preparations
    end
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

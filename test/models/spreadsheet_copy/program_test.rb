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

  test "resolve afternoon hours in source order before mixing acts and preparations" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        { "Horario" => "11:52–12:00", "# Acto" => 5, "Actividad" => "Canto" },
        { "Horario" => "12:00–12:45", "# Acto" => 6, "Actividad" => "Tema" },
        { "Horario" => "12:54–1:09", "# Acto" => 7, "Actividad" => "Animación" },
        { "Horario" => "1:09–1:19", "# Acto" => 7, "Actividad" => "Saludos" },
        { "Horario" => "2:00–3:50", "# Acto" => 8, "Actividad" => "Eucaristía" }
      ],
      "Preparaciones Dom 15" => [
        { "Horario de Preparación" => "11:30 am", "Previo al Acto #" => 5, "Nombre del Acto" => "Preparar canto" },
        { "Horario de Preparación" => "12:35 pm", "Nombre del Acto" => "Preparar animación" },
        { "Horario de Preparación" => "1:30 pm", "Nombre del Acto" => "Preparar eucaristía" }
      ]
    )

    assert_equal [ 712, 720, 774, 789, 840 ], program.acts.map { |act| act.schedule.start_minutes }
    assert_equal [
      "Preparar canto", "Canto", "Tema", "Preparar animación", "Animación", "Saludos", "Preparar eucaristía", "Eucaristía"
    ], program.entries(day: "Domingo 15").map(&:title)
    assert_equal "2:00–3:50", program.acts.last.schedule.to_s
  end

  test "reset noon context for every sheet and do not mistake morning reversals for afternoon" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        { "Horario" => "10:00", "# Acto" => 1, "Actividad" => "Primero" },
        { "Horario" => "09:55", "Actividad" => "Pequeño retroceso" },
        { "Horario" => "13:00", "Actividad" => "Referencia de tarde" },
        { "Horario" => "2:00", "Actividad" => "Después" }
      ],
      "Lunes 16" => [
        { "Horario" => "08:00", "# Acto" => 17, "Actividad" => "Apertura" },
        { "Horario" => "12:56–1:00", "Actividad" => "Palabras finales" },
        { "Horario" => "1:00–2:25", "Actividad" => "Clausura" }
      ],
      "Preparaciones Dom 15" => [
        { "Horario de Preparación" => "09:00", "Previo al Acto #" => 1, "Nombre del Acto" => "Montaje" },
        { "Horario de Preparación" => "1:00 pm", "Nombre del Acto" => "Referencia PM" },
        { "Horario de Preparación" => "2:00", "Nombre del Acto" => "Montaje de tarde" }
      ],
      "Preparaciones Lunes 16" => [
        { "Horario de Preparación" => 27_000, "Previo al Acto #" => 17, "Nombre del Acto" => "Montaje matutino" },
        { "Horario de Preparación" => 45_000, "Nombre del Acto" => "Preparar clausura" },
        { "Horario de Preparación" => nil, "Nombre del Acto" => "Pendiente" },
        { "Horario de Preparación" => 7200, "Nombre del Acto" => "Preparar salida" }
      ]
    )

    assert_equal [ 600, 595, 780, 840, 480, 776, 780 ], program.acts.map { |act| act.schedule.start_minutes }
    assert_equal [ 540, 780, 840, 450, 750, nil, 840 ], program.preparations.map { |preparation| preparation.schedule.start_minutes }
    assert_equal "02:00", program.preparations.last.schedule.to_s
  end

  test "filter entries by type without mixing days and treat unknown filters as all" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [ { "Horario" => "10:00", "# Acto" => 1, "Actividad" => "Inicio" } ],
      "Lunes 16" => [ { "Horario" => "08:00", "# Acto" => 17, "Actividad" => "Apertura del lunes" } ],
      "Preparaciones Dom 15" => [
        { "Horario de Preparación" => "09:30", "Previo al Acto #" => 1, "Nombre del Acto" => "Montaje" }
      ]
    )

    assert_equal [ "Inicio" ], program.entries(day: "Domingo 15", row_type: "acts").map(&:title)
    assert_equal [ "Montaje" ], program.entries(day: "Domingo 15", row_type: "preparations").map(&:title)
    assert_equal [ "Montaje", "Inicio" ], program.entries(day: "Domingo 15", row_type: "unknown").map(&:title)
    assert_empty program.entries(day: "Lunes 16", row_type: "preparations")
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

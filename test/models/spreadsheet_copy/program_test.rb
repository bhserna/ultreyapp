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

  test "map detail columns and preserve line breaks" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        {
          "Horario" => "10:00–10:05", "# Acto" => 1, "Actividad" => "Inicio",
          "Audio" => "  Abrir micrófono\nBajar pista  ",
          "Video / Pantalla" => "Video de bienvenida",
          "Anillo" => "BIENVENIDOS",
          "Iluminación" => "Sala al 60 %",
          "Efectos Especiales" => "Chisperos",
          "Archivos Pendientes" => "Confirmar pista",
          "Archivos Listos" => "Video aprobado"
        }
      ]
    )

    act = program.acts.first

    assert_equal 1, act.position
    assert_equal "Abrir micrófono\nBajar pista", act.audio
    assert_equal "Video de bienvenida", act.screen
    assert_equal "BIENVENIDOS", act.ring
    assert_equal "Sala al 60 %", act.lighting
    assert_equal "Chisperos", act.special_effects
    assert_equal "Confirmar pista", act.pending_files
    assert_equal "Video aprobado", act.ready_files
  end

  test "allow absent and empty detail columns and identify unnumbered acts within their day" do
    program = SpreadsheetCopy::Program.new(
      "Domingo 15" => [
        { "Horario" => "08:30", "# Acto" => nil, "Actividad" => "Entrada", "Audio" => "  " },
        { "Horario" => "09:00", "# Acto" => nil, "Actividad" => "Llamada" }
      ],
      "Lunes 16" => [
        { "Horario" => "08:00", "# Acto" => nil, "Actividad" => "Bienvenida" }
      ]
    )

    assert_equal [ [ "Domingo 15", 1 ], [ "Domingo 15", 2 ], [ "Lunes 16", 1 ] ], program.acts.map { |act| [ act.day, act.position ] }
    program.acts.each do |act|
      assert_nil act.audio
      assert_nil act.screen
      assert_nil act.ring
      assert_nil act.lighting
      assert_nil act.special_effects
      assert_nil act.pending_files
      assert_nil act.ready_files
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

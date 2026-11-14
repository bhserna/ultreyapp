require "test_helper"

class SpreadsheetCopy::ActTest < ActiveSupport::TestCase
  test "build an act from its source columns and preserve detail line breaks" do
    act = SpreadsheetCopy::Act.from_row(
      {
        "Horario" => " 10:00–10:05 ", "# Acto" => 1.0, "Actividad" => " Inicio ",
        "Audio" => "  Abrir micrófono\nBajar pista  ",
        "Video / Pantalla" => "Video de bienvenida",
        "Anillo" => "BIENVENIDOS",
        "Iluminación" => "Sala al 60 %",
        "Efectos Especiales" => "Chisperos",
        "Archivos Pendientes" => "Confirmar pista",
        "Archivos Listos" => "Video aprobado"
      },
      day: "Domingo 15", position: 3
    )

    assert_equal "Domingo 15", act.day
    assert_equal 3, act.position
    assert_equal "Inicio", act.title
    assert_instance_of SpreadsheetCopy::ScheduleTime, act.schedule
    assert_equal "10:00–10:05", act.schedule.to_s
    assert_equal "1", act.number
    assert_equal "Abrir micrófono\nBajar pista", act.audio
    assert_equal "Video de bienvenida", act.screen
    assert_equal "BIENVENIDOS", act.ring
    assert_equal "Sala al 60 %", act.lighting
    assert_equal "Chisperos", act.special_effects
    assert_equal "Confirmar pista", act.pending_files
    assert_equal "Video aprobado", act.ready_files
  end

  test "allow missing schedules numbers and details and turn blank detail text into nil" do
    act = SpreadsheetCopy::Act.from_row(
      { "Actividad" => "Entrada", "Audio" => "  " }, day: "Domingo 15", position: 1
    )

    assert_equal "", act.schedule.to_s
    assert_nil act.number
    assert_nil act.audio
    assert_nil act.screen
    assert_nil act.ring
    assert_nil act.lighting
    assert_nil act.special_effects
    assert_nil act.pending_files
    assert_nil act.ready_files
  end

  test "preserve text act numbers" do
    act = SpreadsheetCopy::Act.from_row(
      { "Actividad" => "Bienvenida", "# Acto" => "02A" }, day: "Lunes 16", position: 1
    )

    assert_equal "02A", act.number
  end

  test "ignore rows with missing or blank activity titles" do
    [ nil, "", "  " ].each do |title|
      assert_nil SpreadsheetCopy::Act.from_row({ "Actividad" => title }, day: "Domingo 15", position: 1)
    end
  end

  test "read the optional stable ID without replacing the position used for navigation" do
    act = SpreadsheetCopy::Act.from_row(
      { "ID" => " act-047 ", "Actividad" => "Apertura" }, day: "Lunes 16", position: 1
    )
    legacy = SpreadsheetCopy::Act.from_row({ "Actividad" => "Apertura" }, day: "Lunes 16", position: 1)

    assert_equal "act-047", act.source_key
    assert_equal "1", act.to_param
    assert_nil legacy.source_key
  end

  test "use the position within its day as the URL parameter rather than the act number" do
    act = SpreadsheetCopy::Act.new(day: "Domingo 15", position: 3, schedule: "10:00", number: 1, title: "Inicio")

    assert_equal "3", act.to_param
  end

  test "an unnumbered activity also has a URL parameter" do
    act = SpreadsheetCopy::Act.new(day: "Domingo 15", position: 1, schedule: "08:30", number: nil, title: "Entrada")

    assert_equal "1", act.to_param
  end
end

require "test_helper"

class SpreadsheetCopy::PreparationTest < ActiveSupport::TestCase
  test "build a preparation using its own time rather than the participation time" do
    preparation = SpreadsheetCopy::Preparation.from_row(
      {
        "Horario de Participación" => "10:05–10:20",
        "Horario de Preparación" => " 09:45 am ",
        "Previo al Acto #" => 2.0,
        "Nombre del Acto" => " Preparar instrumentos "
      },
      day: "Domingo 15", position: 2
    )

    assert_equal "Domingo 15", preparation.day
    assert_equal 2, preparation.position
    assert_equal "Preparar instrumentos", preparation.title
    assert_instance_of SpreadsheetCopy::ScheduleTime, preparation.schedule
    assert_equal "09:45", preparation.schedule.to_s
    assert_equal "2", preparation.act_number
  end

  test "allow missing preparation times and act numbers without falling back to participation time" do
    preparation = SpreadsheetCopy::Preparation.from_row(
      { "Nombre del Acto" => "Montaje", "Horario de Participación" => "02:30–08:00" },
      day: "Domingo 15", position: 1
    )

    assert_equal "", preparation.schedule.to_s
    assert_nil preparation.act_number
  end

  test "preserve free text preparation times and text act identifiers" do
    preparation = SpreadsheetCopy::Preparation.from_row(
      { "Nombre del Acto" => "Montaje", "Horario de Preparación" => "Por confirmar", "Previo al Acto #" => "02A" },
      day: "Domingo 15", position: 1
    )

    assert_equal "Por confirmar", preparation.schedule.to_s
    assert_equal "02A", preparation.act_number
  end

  test "map team instructions and pending items while preserving line breaks" do
    preparation = SpreadsheetCopy::Preparation.from_row(
      {
        "Nombre del Acto" => "Montaje",
        "Actividad para Actos Previos" => "  Recibir invitados\nConfirmar accesos  ",
        "Actividad para Tramoya" => "Colocar pódium",
        "Actividad para Ambientación Coro Arcoiris" => "Preparar instrumentos",
        "Pendientes" => "Confirmar participantes"
      },
      day: "Domingo 15", position: 3
    )

    assert_equal "Recibir invitados\nConfirmar accesos", preparation.previous_acts_instructions
    assert_equal "Colocar pódium", preparation.stage_crew_instructions
    assert_equal "Preparar instrumentos", preparation.choir_instructions
    assert_equal "Confirmar participantes", preparation.pending_items
    assert_equal "3", preparation.to_param
  end

  test "allow absent and blank detail fields for unnumbered preparations" do
    preparation = SpreadsheetCopy::Preparation.from_row(
      { "Nombre del Acto" => "Montaje", "Pendientes" => "  " }, day: "Domingo 15", position: 1
    )

    assert_nil preparation.previous_acts_instructions
    assert_nil preparation.stage_crew_instructions
    assert_nil preparation.choir_instructions
    assert_nil preparation.pending_items
    assert_equal "1", preparation.to_param
  end

  test "ignore rows with missing or blank act names" do
    [ nil, "", "  " ].each do |title|
      assert_nil SpreadsheetCopy::Preparation.from_row({ "Nombre del Acto" => title }, day: "Domingo 15", position: 1)
    end
  end
end

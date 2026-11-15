require "test_helper"

class SpreadsheetCopy::PriorActivityTest < ActiveSupport::TestCase
  test "read the Saturday fields while preserving line breaks" do
    activity = SpreadsheetCopy::PriorActivity.from_row(
      {
        "Horario" => nil,
        "Actividad" => " Recepción de Diócesis ",
        "Responsables" => " AC y Hosp, Parroquias y Centros ",
        "Notas" => "  Confirmar accesos\nRecibir delegaciones  "
      },
      day: "Sábado 14", position: 2
    )

    assert_equal "Sábado 14", activity.day
    assert_equal 2, activity.position
    assert_equal "2", activity.to_param
    assert_equal "Recepción de Diócesis", activity.title
    assert_equal "AC y Hosp, Parroquias y Centros", activity.responsibles
    assert_equal "Confirmar accesos\nRecibir delegaciones", activity.notes
    assert_nil activity.contact
    assert_instance_of SpreadsheetCopy::ScheduleTime, activity.schedule
    assert_equal "", activity.schedule.to_s
  end

  test "read the Sunday contact without treating it as responsibles" do
    activity = SpreadsheetCopy::PriorActivity.from_row(
      {
        "Horario" => " 3:00–08:00 am ",
        "Actividad" => "Instalación de stands",
        "Contacto" => " Lydia "
      },
      day: "Domingo 15", position: 3
    )

    assert_equal "03:00–08:00", activity.schedule.to_s
    assert_equal "Lydia", activity.contact
    assert_nil activity.responsibles
    assert_nil activity.notes
  end

  test "allow absent and blank optional details" do
    activity = SpreadsheetCopy::PriorActivity.from_row(
      { "Actividad" => "Llegada del equipo", "Responsables" => " ", "Contacto" => "", "Notas" => nil },
      day: "Domingo 15", position: 1
    )

    assert_nil activity.responsibles
    assert_nil activity.contact
    assert_nil activity.notes
    assert_nil activity.schedule.start_minutes
  end

  test "ignore rows without an activity title" do
    [ nil, "", " " ].each do |title|
      assert_nil SpreadsheetCopy::PriorActivity.from_row(
        { "Actividad" => title, "Horario" => "6:00 am" }, day: "Domingo 15", position: 1
      )
    end
  end
end

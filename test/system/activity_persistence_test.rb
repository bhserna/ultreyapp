require "application_system_test_case"

class ActivityPersistenceTest < ApplicationSystemTestCase
  test "reads persisted act attributes while retaining existing production and question references" do
    activity = Activity.find(1)
    activity.update!(title: "Acto actualizado en la base de datos", start_time: "10:01")
    ProductionDetail.create!(schedule_entry_id: activity.id, executors: "Equipo asignado manualmente", notes: "Notas guardadas")
    Question.create!(schedule_entry_id: activity.id, body: "Pregunta guardada del acto")

    visit root_path(day: activity.day, row_type: "acts")
    within(:schedule_act, "Acto actualizado en la base de datos") do
      assert_selector :schedule_cell, :start_time, text: "10:01"
      click_link "Ver detalle"
    end

    assert_current_path schedule_entry_path(1)
    assert_selector "h1", text: "Acto actualizado en la base de datos"
    assert_text "Equipo asignado manualmente"
    assert_text "Notas guardadas"
    assert_text "Pregunta guardada del acto"
  end

  test "reads persisted operation details and filters while preserving its original URL" do
    operation = Activity.find_operation_by_source_id(3)
    operation.update!(
      title: "Operación actualizada en la base de datos", day: "Lunes 16", phase: "program",
      start_time: "Por confirmar", end_time: "10:05", commissions: [ "Equipo nuevo" ],
      details: operation.details.merge("audio" => "Audio guardado", "notes" => "Notas de operación guardadas")
    )

    visit root_path(day: "Lunes 16", commission: "Equipo nuevo", row_type: "operations")
    assert_selector :schedule_operation, count: 1
    within(:schedule_operation, "Operación actualizada en la base de datos") { click_link "Ver detalle" }

    assert_current_path operational_activity_path(3)
    assert_selector "h1", text: "Operación actualizada en la base de datos"
    assert_selector :activity_metadata, "Inicio", text: "Por confirmar"
    assert_text "Audio guardado"
    assert_text "Notas de operación guardadas"
    assert_no_link "Editar operación"

    visit root_path(day: "Domingo 15", commission: "Equipo nuevo", row_type: "operations")
    assert_no_selector :schedule_operation
  end
end

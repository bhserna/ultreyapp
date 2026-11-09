require "application_system_test_case"

class OperationsTest < ApplicationSystemTestCase
  test "show operation details" do
    operation = activities(:reception)
    act = activities(:opening_act)
    assert_equal act.id, operation.source_id
    Question.create!(act_id: act.id, body: "Pregunta exclusiva del acto")
    ProductionDetail.create!(act_id: act.id, executors: "Equipo exclusivo del acto")

    visit operational_activity_path(operation.source_id)

    assert_selector "h1", text: operation.title
    assert_selector :activity_metadata, "Inicio", text: operation.start_time
    assert_text operation.executors
    assert_text operation.notes
    assert_text operation.production_detail.audio
    assert_no_text "Pregunta exclusiva del acto"
    assert_no_text "Equipo exclusivo del acto"
    assert_no_link "Agregar detalles de producción"
  end
end

require "application_system_test_case"

class SpreadsheetPriorActivitiesTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "browse prior activities across days and return to the selected copy and filter" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_prior_activities.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit current_program_path
    assert_current_path spreadsheet_copy_day_path(copy, "Sábado 14")
    select "Actividades previas", from: "Tipo de actividad"
    within "tr", text: "Recepción de Diócesis" do
      click_link "Ver detalle"
    end
    assert_current_path spreadsheet_copy_day_prior_activity_path(copy, "Sábado 14", 1, row_type: "prior_activities")
    assert_selector "h1", text: "Recepción de Diócesis"

    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(copy, "Sábado 14", row_type: "prior_activities")
    assert_select "Tipo de actividad", selected: "Actividades previas"
    click_link "Domingo 15"
    within "tr", text: "Prueba de sonido e iluminación" do
      click_link "Ver detalle"
    end
    assert_current_path spreadsheet_copy_day_prior_activity_path(copy, "Domingo 15", 1, row_type: "prior_activities")
    assert_selector "h1", text: "Prueba de sonido e iluminación"
    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "prior_activities")

    select "Todo", from: "Tipo de actividad"
    assert_text "Actividad previa · Prueba de sonido e iluminación"
    assert_text "Preparación ·"
    assert_text "Inicio / Video"
    click_link "Sábado 14"
    select "Actos", from: "Tipo de actividad"
    assert_text "No hay actividades de este tipo para este día."
  end
end

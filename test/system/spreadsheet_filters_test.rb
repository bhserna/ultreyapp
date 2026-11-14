require "application_system_test_case"

class SpreadsheetFiltersTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "filter types and preserve the selection across days and act details" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit current_program_path

    select "Actos", from: "Tipo de actividad"
    assert_current_path spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "acts")
    assert_no_selector :schedule_preparation
    assert_text "Entrada a la Arena"

    click_link "Lunes 16"
    assert_current_path spreadsheet_copy_day_path(copy, "Lunes 16", row_type: "acts")
    assert_select "Tipo de actividad", selected: "Actos"
    assert_no_text "Preparar apertura del lunes"
    within "tr", text: "Bienvenida del lunes" do
      click_link "Ver detalle"
    end
    assert_selector "h1", text: "Bienvenida del lunes"
    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(copy, "Lunes 16", row_type: "acts")
    assert_select "Tipo de actividad", selected: "Actos"

    select "Preparaciones", from: "Tipo de actividad"
    assert_current_path spreadsheet_copy_day_path(copy, "Lunes 16", row_type: "preparations")
    assert_text "Preparar apertura del lunes"
    assert_no_text "Bienvenida del lunes"
    assert_no_link "Ver detalle"

    click_link "Domingo 15"
    assert_current_path spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
    assert_select "Tipo de actividad", selected: "Preparaciones"
    assert_text "Preparar instrumentos"
    assert_no_text "Entrada a la Arena"

    select "Todo", from: "Tipo de actividad"
    assert_text "Entrada a la Arena"
    assert_text "Preparar instrumentos"
    assert_link "Ver detalle"
  end

  test "show an empty state for missing preparations and ignore unknown filters" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_day_path(copy, "Lunes 16", row_type: "preparations")

    assert_select "Tipo de actividad", selected: "Preparaciones"
    assert_text "No hay actividades de este tipo para este día."
    assert_no_link "Ver detalle"

    visit spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "unknown")

    assert_select "Tipo de actividad", selected: "Todo"
    assert_text "Entrada a la Arena"
    assert_text "Preparar instrumentos"
  end
end

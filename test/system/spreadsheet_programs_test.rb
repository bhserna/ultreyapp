require "application_system_test_case"

class SpreadsheetProgramsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile
  test "filter the latest copy by the day of each act" do
    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE), created_at: 1.day.ago)
    SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit root_path

    assert_selector ".site-nav a[aria-current=page]", text: "Programa actualizado"
    assert_selector "h1", text: "Programa actualizado"
    assert_selector ".tabs a[aria-current=page]", text: "Domingo 15"
    assert_text "Entrada a la Arena"
    assert_no_text "Bienvenida del lunes"
    click_link "Lunes 16"
    assert_selector ".tabs a[aria-current=page]", text: "Lunes 16"
    assert_text "Bienvenida del lunes"
    assert_no_text "Entrada a la Arena"

    within ".site-nav" do
      assert_no_link "Programa", exact: true
      assert_no_link "Preguntas generales"
      assert_link "Copias del spreadsheet"
    end
  end

  test "read renamed act sheets with IDs and preserve day and preparation navigation" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_renamed_sheets.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit current_program_path

    assert_current_path spreadsheet_copy_day_path(copy, "Domingo 15")
    assert_selector ".tabs a[aria-current=page]", text: "Domingo 15"
    assert_text "Entrada a la Arena"
    assert_text "Preparar instrumentos"
    assert_no_text "Recepción de Diócesis"
    within "tr", text: "Preparar instrumentos" do
      click_link "Ver detalle"
    end
    assert_selector "h1", text: "Preparar instrumentos"
    assert_selector :related_act, text: "Grupo Folklórico"
    click_link "← Volver al programa"
    click_link "Lunes 16"

    assert_current_path spreadsheet_copy_day_path(copy, "Lunes 16")
    assert_text "Bienvenida del lunes"
    assert_text "Preparar apertura del lunes"
    within "tr", text: "Bienvenida del lunes" do
      click_link "Ver detalle"
    end
    assert_selector "h1", text: "Bienvenida del lunes"
    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(copy, "Lunes 16")
  end

  test "explain how to get started when there are no copies" do
    visit current_program_path

    assert_text "Todavía no hay copias del spreadsheet."
    assert_current_path spreadsheet_copies_path
    assert_button "Descargar copia"
  end

  test "an unreadable copy leaves the saved files accessible" do
    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit current_program_path

    assert_selector "[role=alert]", text: "No se pudo mostrar el programa de esta copia."
    click_link "Ver copias del spreadsheet"
    assert_link "Descargar archivo"
  end
end

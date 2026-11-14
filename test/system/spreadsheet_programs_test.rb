require "application_system_test_case"

class SpreadsheetProgramsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile
  test "filter the latest copy by the day of each act" do
    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE), created_at: 1.day.ago)
    SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit root_path
    click_link "Programa actualizado"

    assert_selector ".site-nav a[aria-current=page]", text: "Programa actualizado"
    assert_selector "h1", text: "Programa actualizado"
    assert_text "Copia descargada el"
    assert_no_selector ".page__section"
    assert_no_selector "h2"
    within "table" do
      assert_selector "thead th", text: "Horario"
      assert_selector "thead th", text: "Acto"
      assert_selector "thead th", text: "Actividad"
      assert_selector "tbody tr", count: 4
      within all("tbody tr").first do
        assert_selector "td", text: "08:30–09:30"
        assert_selector "td", exact_text: "—"
        assert_text "Entrada a la Arena"
      end
      within all("tbody tr")[1] do
        assert_selector "td", exact_text: "1"
        assert_text "Inicio / Video"
      end
    end
    assert_no_text "Bienvenida del lunes"
    click_link "Lunes 16"
    assert_selector ".tabs a[aria-current=page]", text: "Lunes 16"
    within "table" do
      assert_selector "tbody tr", count: 2
      assert_text "Bienvenida del lunes"
      assert_text "02A"
    end
    assert_no_text "Entrada a la Arena"
    assert_no_text "Preparar instrumentos"

    visit spreadsheet_program_path(day: "Día desconocido")
    assert_selector ".tabs a[aria-current=page]", text: "Domingo 15"
    assert_text "Entrada a la Arena"

    click_link "Programa", exact: true
    assert_current_path root_path
    assert_selector "h1", exact_text: "Programa"
  end

  test "explain how to get started when there are no copies" do
    visit spreadsheet_program_path

    assert_text "Todavía no hay copias del spreadsheet."
    click_link "Ver copias del spreadsheet"
    assert_current_path spreadsheet_copies_path
  end

  test "an unreadable copy leaves the saved files accessible" do
    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit spreadsheet_program_path

    assert_selector "[role=alert]", text: "No se pudo mostrar el programa de esta copia."
    click_link "Ver copias del spreadsheet"
    assert_link "Descargar archivo"
  end
end

require "application_system_test_case"

class SpreadsheetPrintoutsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "print the selected day and filter or expand to the whole copy" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
    click_link "Versión para imprimir"

    assert_select "Días", selected: "Domingo 15"
    assert_select "Tipo de actividad", selected: "Preparaciones"
    assert_selector "table", count: 1
    assert_selector "caption.visually-hidden", text: "Programa de actividades para Domingo 15"
    assert_selector "article", text: "Preparar instrumentos"
    assert_no_text "Entrada a la Arena"
    assert_no_text "Preparar apertura del lunes"

    select "Todo el programa", from: "Días"
    click_button "Actualizar vista"
    assert_selector "article", text: "Preparar apertura del lunes"
    assert_selector "article", text: "Preparar instrumentos"

    uncheck "Incluir detalles"
    click_button "Actualizar vista"
    assert_no_selector "article"
    assert_selector "table", text: "Preparar instrumentos"

    page.current_window.resize_to(390, 844)
    assert_selector ".printout__settings", text: "Preparar impresión"
    assert page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth"), "Print settings should fit a mobile viewport"

    page.execute_script("window.print = () => { window.printRequested = true }")
    click_button "Imprimir / Guardar PDF"
    assert page.evaluate_script("window.printRequested === true")

    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")
    assert_no_selector ".printout__controls"
    assert_no_selector ".site-nav"
    assert_selector "table", text: "Preparar instrumentos"
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
    page.current_window.resize_to(1400, 900)
  end
end

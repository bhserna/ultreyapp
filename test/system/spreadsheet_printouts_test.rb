require "application_system_test_case"

class SpreadsheetPrintoutsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "print compact details inside the activity cells and keep each activity together on a page" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_printout_path(copy)

    assert_selector ".printout__day + .printout__day"
    assert_selector "td .printout__details"
    assert_no_selector "article"
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")

    day = find(".printout__day + .printout__day", match: :first)
    assert_equal "auto", day.evaluate_script("getComputedStyle(this).breakBefore")
    assert_equal "solid", day.evaluate_script("getComputedStyle(this).borderTopStyle")
    all(".printout__entry").each do |row|
      assert_equal "auto", row.evaluate_script("getComputedStyle(this).breakBefore")
      assert_equal "avoid", row.evaluate_script("getComputedStyle(this).breakInside")
    end
    within "tr", text: "Preparar instrumentos" do
      label = find("dt", text: "Tramoya:")
      assert_operator label.evaluate_script("Number(getComputedStyle(this).fontWeight)"), :>=, 700
      assert_equal "inline", label.evaluate_script("getComputedStyle(this).display")
      details = find(".printout__details")
      title = find(".printout__title")
      assert_operator details.evaluate_script("parseFloat(getComputedStyle(this).fontSize)"), :<,
        title.evaluate_script("parseFloat(getComputedStyle(this).fontSize)")
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
  end

  test "print the selected day and filter or expand to the whole copy" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
    click_link "Versión para imprimir"

    assert_no_field "Empezar cada actividad y día en una hoja nueva"
    assert_select "Días", selected: "Domingo 15"
    assert_select "Tipo de actividad", selected: "Preparaciones"
    assert_selector "table", count: 1
    assert_selector "caption.visually-hidden", text: "Programa de actividades para Domingo 15"
    within "table" do
      assert_selector "thead th", count: 3
      assert_no_selector "th", exact_text: "Tipo"
    end
    within "tr", text: "Preparar instrumentos" do
      assert_selector "td", count: 3
      assert_selector "td", exact_text: "09:45"
      assert_selector ".printout__title strong", exact_text: "Preparación"
      assert_selector ".printout__title", exact_text: "Preparación · Preparar instrumentos"
      assert_selector ".printout__details dt", text: "Tramoya:"
    end
    assert_no_text "09:45 am"
    assert_no_text "Entrada a la Arena"
    assert_no_text "Preparar apertura del lunes"

    select "Todo el programa", from: "Días"
    click_button "Actualizar vista"
    assert_selector "td .printout__title", text: "Preparar apertura del lunes"
    assert_selector "td .printout__title", text: "Preparar instrumentos"

    uncheck "Incluir detalles"
    click_button "Actualizar vista"
    assert_no_selector ".printout__details"
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
    within "tr", text: "Preparar instrumentos" do
      label = find("strong", text: "Preparación")
      assert_operator label.evaluate_script("Number(getComputedStyle(this).fontWeight)"), :>=, 700
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
    page.current_window.resize_to(1400, 900)
  end
end

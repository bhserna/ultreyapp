require "application_system_test_case"

class SpreadsheetPrintoutsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "print days and activity details continuously with separator lines" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_printout_path(copy)

    assert_selector ".printout__day + .printout__day"
    assert_selector ".printout__entry"
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")

    [ ".printout__day + .printout__day", ".printout__entry" ].each do |selector|
      styles = page.evaluate_script(<<~JS, selector)
        Array.from(document.querySelectorAll(arguments[0]), element => {
          const style = getComputedStyle(element);
          return [style.breakBefore, style.borderTopStyle, style.borderTopWidth];
        })
      JS
      styles.each do |break_before, border_style, border_width|
        assert_equal "auto", break_before
        assert_equal "solid", border_style
        assert_equal "1px", border_width
      end
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
  end

  test "optionally start each day and activity on a new page" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_printout_path(copy)

    assert_unchecked_field "Empezar cada actividad y día en una hoja nueva"
    check "Empezar cada actividad y día en una hoja nueva"
    click_button "Actualizar vista"
    assert_checked_field "Empezar cada actividad y día en una hoja nueva"
    assert_selector ".printout--page-breaks"

    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")
    [ ".printout__day + .printout__day", ".printout__entry" ].each do |selector|
      element = find(selector, match: :first)
      assert_equal "page", element.evaluate_script("getComputedStyle(this).breakBefore")
      assert_equal "0px", element.evaluate_script("getComputedStyle(this).borderTopWidth")
    end

    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
    uncheck "Empezar cada actividad y día en una hoja nueva"
    click_button "Actualizar vista"
    assert_unchecked_field "Empezar cada actividad y día en una hoja nueva"
    assert_no_selector ".printout--page-breaks"
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")
    assert_equal "auto", find(".printout__entry", match: :first).evaluate_script("getComputedStyle(this).breakBefore")
  ensure
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "")
  end

  test "print the selected day and filter or expand to the whole copy" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
    click_link "Versión para imprimir"

    assert_select "Días", selected: "Domingo 15"
    assert_select "Tipo de actividad", selected: "Preparaciones"
    assert_selector "table", count: 1
    assert_selector "caption.visually-hidden", text: "Programa de actividades para Domingo 15"
    assert_selector "article", text: "Preparar instrumentos"
    within "tr", text: "Preparar instrumentos" do
      assert_selector "td", exact_text: "09:45"
    end
    within "article", text: "Preparar instrumentos" do
      assert_selector "dd", exact_text: "09:45"
    end
    assert_no_text "09:45 am"
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

require "application_system_test_case"
require_relative "../support/spreadsheet_server"

class SpreadsheetCopiesTest < ApplicationSystemTestCase
  include SpreadsheetServer

  test "download copies from the new tab and keep earlier downloads available" do
    with_spreadsheet_response(body: spreadsheet_content) do
      visit root_path
      click_link "Copias del spreadsheet"
      assert_text "Todavía no hay copias del spreadsheet."

      click_button "Descargar copia"
      assert_text "La copia del spreadsheet se guardó correctamente."
      assert_selector "tbody tr", count: 1
      assert_selector "tbody time", count: 1, text: /\d{1,2} de [a-z]+ de \d{4}, \d{2}:\d{2} UTC/
      assert_link "Descargar archivo", count: 1
      button = find_button("Descargar copia")
      assert_equal "rgb(56, 84, 115)", button.evaluate_script("getComputedStyle(this).backgroundColor")
      assert_equal "rgb(255, 255, 255)", button.evaluate_script("getComputedStyle(this).color")

      link = find_link("Descargar archivo")
      assert_equal "rgb(56, 84, 115)", link.evaluate_script("getComputedStyle(this).color")
      assert_equal "underline", link.evaluate_script("getComputedStyle(this).textDecorationLine")

      click_button "Descargar copia"
      assert_selector "tbody tr", count: 2
      assert_link "Descargar archivo", count: 2
    end
  end

  test "a download error leaves the page usable" do
    with_spreadsheet_response(body: "Unavailable", status: "503 Service Unavailable") do
      visit spreadsheet_copies_path
      click_button "Descargar copia"
      assert_selector "[role=alert]", text: "No se pudo descargar el spreadsheet."
      assert_button "Descargar copia"
      assert_text "Todavía no hay copias del spreadsheet."
    end
  end
end

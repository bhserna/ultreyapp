require "application_system_test_case"

class SpreadsheetPreparationsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "list preparations alongside acts using preparation times and keeping days separate" do
    SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit current_program_path

    assert_selector "tbody tr", count: 7
    within all("tbody tr").first do
      assert_text "Preparación · Instalación y Montaje"
      assert_selector "td", exact_text: "—", count: 2
      assert_no_link "Ver detalle"
    end
    within "tr", text: "Preparar instrumentos" do
      assert_text "09:45 am"
      assert_text "Previo al 2"
      assert_no_text "10:05–10:20"
      assert_no_link "Ver detalle"
      assert_equal "rgb(225, 239, 250)", evaluate_script("getComputedStyle(document.querySelector('tr.schedule__preparation')).backgroundColor")
    end
    titles = all("tbody .schedule__activity").map(&:text)
    assert_operator titles.index("Preparación · Preparar bienvenida"), :<, titles.index("Inicio / Video")
    assert_no_text "Instrucciones que no van en la lista"
    assert_no_text "Preparar apertura del lunes"

    within "tr", text: "Grupo Folklórico" do
      assert_link "Ver detalle"
    end

    click_link "Lunes 16"
    within "tr", text: "Preparar apertura del lunes" do
      assert_text "07:30"
      assert_text "Previo al 1"
      assert_no_link "Ver detalle"
    end
    assert_no_text "Instalación y Montaje"
    assert_no_text "Preparar instrumentos"
  end
end

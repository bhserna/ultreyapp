require "application_system_test_case"

class SpreadsheetPreparationsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "keep afternoon preparations before their acts without changing the displayed times" do
    SpreadsheetCopy.create!(file: fixture_file_upload("program_noon.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit current_program_path

    assert_equal [
      "Preparación · Preparar canto", "Canto de Colores", "Tema de la mañana",
      "Preparación · Preparar animación", "Animación", "Saludos", "Preparación · Preparar eucaristía", "Eucaristía"
    ], all("tbody .schedule__activity").map(&:text)
    within "tr", text: "Preparar eucaristía" do
      assert_text "1:30 pm"
    end
    within "tr", text: "Eucaristía" do
      click_link "Ver detalle"
    end
    assert_text "2:00–3:50"
    click_link "← Volver al programa"
    click_link "Lunes 16"
    assert_selector ".tabs a[aria-current=page]", text: "Lunes 16"
    assert_text "Apertura del lunes"

    assert_equal [
      "Preparación · Preparar apertura", "Apertura del lunes", "Preparación · Preparar clausura", "Palabras finales",
      "Eucaristía de clausura", "Preparación · Preparar salida", "Entrega de comida y salida"
    ], all("tbody .schedule__activity").map(&:text)
    within "tr", text: "Preparar salida" do
      assert_text "02:00"
    end
  end

  test "list preparations alongside acts using preparation times and keeping days separate" do
    SpreadsheetCopy.create!(file: fixture_file_upload("program_preparations.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit current_program_path

    assert_selector "tbody tr", count: 7
    within all("tbody tr").first do
      assert_text "Preparación · Instalación y Montaje"
      assert_selector "td", exact_text: "—", count: 2
      assert_link "Ver detalle"
    end
    within "tr", text: "Preparar instrumentos" do
      assert_text "09:45 am"
      assert_selector "td", exact_text: "2"
      assert_no_text "Previo"
      assert_no_text "10:05–10:20"
      assert_link "Ver detalle"
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
      assert_selector "td", exact_text: "1"
      assert_no_text "Previo"
      assert_link "Ver detalle"
    end
    assert_no_text "Instalación y Montaje"
    assert_no_text "Preparar instrumentos"
  end
end

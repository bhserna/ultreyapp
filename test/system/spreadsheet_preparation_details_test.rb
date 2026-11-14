require "application_system_test_case"

class SpreadsheetPreparationDetailsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "show team instructions and related segments from the same copy and return with the filter" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("preparation_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
    within "tr", text: "Preparar bienvenida" do
      click_link "Ver detalle"
    end

    assert_selector "h1", text: "Preparar bienvenida"
    assert_selector ".page__eyebrow", text: "DOMINGO 15 · PREPARACIÓN"
    assert_selector :activity_metadata, "Horario de preparación", text: "10:00"
    assert_text "Copia descargada el"
    assert_no_text "Horario de participación"
    within "section[aria-label='Instrucciones de preparación']" do
      assert_selector "h3", text: "Actos previos"
      assert_text "Recibir invitados"
      assert_text "Confirmar accesos <b>sin bloquear</b>."
      assert_selector "p br", visible: :all
      assert_no_selector "b"
      assert_selector "h3", text: "Tramoya"
      assert_text "Colocar pódium"
      assert_selector "h3", text: "Ambientación / Coro Arcoiris"
      assert_text "Preparar instrumentos"
      assert_selector "h3", text: "Pendientes"
      assert_text "Confirmar participantes"
    end
    assert_selector :related_act, count: 2
    assert_selector :related_act, text: "Inicio / Video"
    assert_selector :related_act, text: "Segundo segmento de bienvenida"
    assert_no_selector :related_act, text: "Bienvenida del lunes"
    assert_no_link "Editar detalles"

    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    find(:related_act, text: "Inicio / Video").click
    assert_selector "h1", exact_text: "Inicio / Video"
    assert_current_path spreadsheet_copy_day_act_path(copy, "Domingo 15", 2, row_type: "preparations")
    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
    assert_select "Tipo de actividad", selected: "Preparaciones"

    within "tr", text: "Preparar bienvenida" do
      click_link "Ver detalle"
    end
    assert_selector "h1", text: "Preparar bienvenida"
    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
  end

  test "preparations without related acts or instructions still have a detail page" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("preparation_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    visit spreadsheet_copy_day_preparation_path(copy, "Domingo 15", 1)
    assert_selector "h1", text: "Instalación y Montaje"
    assert_selector :activity_metadata, "Horario de preparación", text: "—"
    assert_no_selector :related_act
    assert_no_selector "section[aria-label='Instrucciones de preparación']"

    visit spreadsheet_copy_day_preparation_path(copy, "Domingo 15", 4)
    assert_selector "h1", text: "Preparación sin coincidencias"
    assert_no_selector :related_act
    assert_no_selector "h2", text: "Actos relacionados"
  end
end

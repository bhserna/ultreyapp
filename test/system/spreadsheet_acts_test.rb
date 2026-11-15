require "application_system_test_case"

class SpreadsheetActsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "open an unnumbered act and return to the same copy and day after a new download" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit current_program_path

    within "tr", text: "Entrada a la Arena" do
      click_link "Ver detalle"
    end

    assert_selector "h1", text: "Entrada a la Arena"
    assert_selector ".page__eyebrow", text: "DOMINGO 15"
    assert_text "08:30–09:30"
    assert_text "Copia descargada el"
    assert_no_selector "dt", exact_text: "Acto"
    assert_selector ".site-nav a[aria-current=page]", text: "Programa actualizado"
    within :activity_details do
      assert_selector "h3", text: "Audio"
      assert_text "Playlist instrumental"
      assert_text "Bajar volumen al terminar la entrada."
      assert_selector "p br", visible: :all
      assert_selector "b", text: "la entrada"
      assert_no_text "<b>"
      assert_text "Video de bienvenida"
      assert_text "BIENVENIDOS"
      assert_text "Sala al 60 %"
      assert_text "Confirmar pista"
      assert_text "Video aprobado"
      assert_no_selector "h3", text: "Efectos especiales"
    end
    assert_no_link "Editar detalles"
    assert_no_text "Preguntas para este acto"

    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    click_link "← Volver al programa"

    assert_current_path spreadsheet_copy_day_path(copy, "Domingo 15")
    assert_text "Entrada a la Arena"
    click_link "Lunes 16"
    assert_current_path spreadsheet_copy_day_path(copy, "Lunes 16")
    within "tr", text: "Bienvenida del lunes" do
      click_link "Ver detalle"
    end
    assert_selector "h1", text: "Bienvenida del lunes"
    assert_selector ".page__eyebrow", text: "LUNES 16"
    assert_selector "dt", text: "Acto"
    assert_no_selector :activity_details

    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(copy, "Lunes 16")
    assert_text "Bienvenida del lunes"
    assert_no_text "Entrada a la Arena"
  end
end

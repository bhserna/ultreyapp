require "test_helper"

class SpreadsheetPriorActivitiesIntegrationTest < ActionDispatch::IntegrationTest
  test "unknown activity references do not fall back to another day or copy" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_prior_activities.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    [ "0", "-1", "99", "1junk", "01" ].each do |position|
      get spreadsheet_copy_day_prior_activity_path(copy, "Sábado 14", position)
      assert_response :not_found
    end
    get spreadsheet_copy_day_prior_activity_path(copy, "Lunes 16", 1)
    assert_response :not_found
    get spreadsheet_copy_day_prior_activity_path(copy, "Día desconocido", 1)
    assert_response :not_found
    get spreadsheet_copy_day_prior_activity_path(SpreadsheetCopy.maximum(:id) + 1, "Sábado 14", 1)
    assert_response :not_found
  end

  test "details escape spreadsheet text and do not offer documents or editing" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_prior_activities.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get spreadsheet_copy_day_prior_activity_path(copy, "Sábado 14", 1)

    assert_select "h1", text: "Recepción de Diócesis"
    assert_select "dd", text: "—"
    assert_select "h3", text: "Responsables"
    assert_select "h3", text: "Notas"
    assert_select "h3", text: "Contacto", count: 0
    assert_select "p", text: /Al menos uno por comisión <b>sin bloquear<\/b>\./
    assert_select "p br"
    assert_select "b", count: 0
    assert_select "turbo-frame#documents, input[type=file]", count: 0
    assert_select "a", text: "Editar detalles", count: 0

    get spreadsheet_copy_day_prior_activity_path(copy, "Domingo 15", 1)

    assert_select "dd", text: "06:00"
    assert_select "h3", text: "Contacto"
    assert_select "h3", text: "Responsables", count: 0
    assert_select "h3", text: "Notas", count: 0

    get spreadsheet_copy_day_prior_activity_path(copy, "Domingo 15", 10)

    assert_response :success
    assert_select "section[aria-label='Detalles de la actividad previa']", count: 0
    assert_select "dd", text: "—"
  end

  test "older copies have no prior activity day or detail and unreadable files keep the recovery link" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get spreadsheet_copy_day_prior_activity_path(copy, "Domingo 15", 1)
    assert_response :not_found
    get spreadsheet_copy_day_path(copy, "Sábado 14")
    assert_response :not_found
    get spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "prior_activities")
    assert_response :success
    assert_select "td", text: "No hay actividades de este tipo para este día."

    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    get spreadsheet_copy_day_prior_activity_path(copy, "Sábado 14", 1)

    assert_select "[role=alert]", text: /No se pudo mostrar el programa de esta copia/
    assert_select "a[href=?]", spreadsheet_copies_path, text: "Ver copias del spreadsheet"
  end
end

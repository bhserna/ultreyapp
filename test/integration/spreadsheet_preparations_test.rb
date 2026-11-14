require "test_helper"

class SpreadsheetPreparationsIntegrationTest < ActionDispatch::IntegrationTest
  test "unknown preparation references do not fall back to another day or copy" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("preparation_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    [ "0", "-1", "99", "1junk" ].each do |position|
      get spreadsheet_copy_day_preparation_path(copy, "Domingo 15", position)
      assert_response :not_found
    end

    get spreadsheet_copy_day_preparation_path(copy, "Día desconocido", 1)
    assert_response :not_found

    get spreadsheet_copy_day_preparation_path(SpreadsheetCopy.maximum(:id) + 1, "Domingo 15", 1)
    assert_response :not_found
  end

  test "an unreadable preparation copy keeps its saved file accessible" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get spreadsheet_copy_day_preparation_path(copy, "Domingo 15", 1)

    assert_select "[role=alert]", text: /No se pudo mostrar el programa de esta copia/
    assert_select "a[href=?]", spreadsheet_copies_path, text: "Ver copias del spreadsheet"
  end
end

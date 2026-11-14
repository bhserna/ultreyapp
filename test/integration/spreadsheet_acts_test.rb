require "test_helper"

class SpreadsheetActsIntegrationTest < ActionDispatch::IntegrationTest
  test "unknown positions and days do not fall back to another act" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    [ "0", "-1", "99", "1junk" ].each do |position|
      get spreadsheet_copy_day_act_path(copy, "Domingo 15", position)
      assert_response :not_found
    end

    get spreadsheet_copy_day_act_path(copy, "Día desconocido", 1)
    assert_response :not_found

    get spreadsheet_copy_day_path(copy, "Día desconocido")
    assert_response :not_found
  end

  test "an unknown copy does not use the latest copy" do
    SpreadsheetCopy.create!(file: fixture_file_upload("program_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    missing_id = SpreadsheetCopy.maximum(:id) + 1

    get spreadsheet_copy_day_act_path(missing_id, "Domingo 15", 1)
    assert_response :not_found

    get spreadsheet_copy_day_path(missing_id, "Domingo 15")
    assert_response :not_found

    get spreadsheet_copy_program_path(missing_id)
    assert_response :not_found
  end

  test "an unreadable copy keeps its error and saved files accessible through every resource" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    [
      spreadsheet_copy_program_path(copy),
      spreadsheet_copy_day_path(copy, "Domingo 15"),
      spreadsheet_copy_day_act_path(copy, "Domingo 15", 1)
    ].each do |path|
      get path

      assert_select "[role=alert]", text: /No se pudo mostrar el programa de esta copia/
      assert_select "a[href=?]", spreadsheet_copies_path, text: "Ver copias del spreadsheet"
    end
  end
end

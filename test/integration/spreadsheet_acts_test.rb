require "test_helper"

class SpreadsheetActsIntegrationTest < ActionDispatch::IntegrationTest
  test "unknown positions and days do not fall back to another act" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    [ "0", "-1", "99", "1junk" ].each do |position|
      get spreadsheet_copy_act_path(copy, position, day: "Domingo 15")
      assert_response :not_found
    end

    get spreadsheet_copy_act_path(copy, 1, day: "Día desconocido")
    assert_response :not_found

    get spreadsheet_copy_act_path(copy, 1)
    assert_response :not_found
  end

  test "an unknown copy does not use the latest copy" do
    SpreadsheetCopy.create!(file: fixture_file_upload("program_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    missing_id = SpreadsheetCopy.maximum(:id) + 1

    get spreadsheet_copy_act_path(missing_id, 1, day: "Domingo 15")
    assert_response :not_found

    get spreadsheet_program_path(copy_id: missing_id)
    assert_response :not_found
  end

  test "an unreadable act copy returns to that copy's program error" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get spreadsheet_copy_act_path(copy, 1, day: "Domingo 15")

    assert_redirected_to spreadsheet_program_path(copy_id: copy.id, day: "Domingo 15")
  end
end

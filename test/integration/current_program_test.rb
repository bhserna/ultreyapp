require "test_helper"

class CurrentProgramIntegrationTest < ActionDispatch::IntegrationTest
  test "home temporarily redirects to the current program" do
    get root_path

    assert_response :found
    assert_redirected_to current_program_path
  end

  test "the previous spreadsheet program path redirects to the current program" do
    get "/spreadsheet_program"

    assert_response :found
    assert_redirected_to current_program_path
  end

  test "the current program temporarily redirects to the newest copy and its first day" do
    SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE), created_at: 1.day.ago)
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get current_program_path

    assert_response :found
    assert_redirected_to spreadsheet_copy_program_path(copy)
    follow_redirect!
    assert_response :found
    assert_redirected_to spreadsheet_copy_day_path(copy, "Domingo 15")
  end

  test "a specific program keeps its copy even when there is a newer one" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE), created_at: 1.day.ago)
    SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get spreadsheet_copy_program_path(copy)

    assert_redirected_to spreadsheet_copy_day_path(copy, "Domingo 15")
  end

  test "without copies the current program redirects to the download page" do
    get current_program_path

    assert_redirected_to spreadsheet_copies_path
  end
end

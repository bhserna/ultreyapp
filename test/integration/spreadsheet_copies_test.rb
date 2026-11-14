require "test_helper"

class SpreadsheetCopiesIntegrationTest < ActionDispatch::IntegrationTest
  test "the saved copy can be downloaded as the original file" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get spreadsheet_copies_url
    download_url = css_select("tbody a").sole["href"]
    get download_url
    follow_redirect!

    assert_response :success
    assert_equal file_fixture("spreadsheet.xlsx").binread, response.body.b
    assert_includes response.headers["Content-Disposition"], "attachment"
    assert_includes response.headers["Content-Disposition"], copy.file.filename.to_s
  end

  test "display download dates in Monterrey time" do
    SpreadsheetCopy.create!(
      file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE),
      created_at: Time.utc(2026, 11, 14, 19, 4)
    )

    get spreadsheet_copies_url

    assert_select "tbody time", text: "14 de noviembre de 2026, 13:04 CST"
  end
end

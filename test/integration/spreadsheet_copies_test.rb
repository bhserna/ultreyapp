require "test_helper"
require_relative "../support/spreadsheet_server"

class SpreadsheetCopiesIntegrationTest < ActionDispatch::IntegrationTest
  include SpreadsheetServer

  test "each download saves the original file in a separate copy" do
    with_spreadsheet_response(body: spreadsheet_content) do
      2.times do
        assert_difference "SpreadsheetCopy.count", 1 do
          post spreadsheet_copies_url
        end
        assert_redirected_to spreadsheet_copies_url
      end
    end

    copies = SpreadsheetCopy.order(:id).last(2)
    copies.each do |copy|
      assert_equal spreadsheet_content, copy.file.download
      assert_equal SpreadsheetCopy::CONTENT_TYPE, copy.file.content_type
    end
    assert_not_equal copies.first.file.blob_id, copies.last.file.blob_id

    get spreadsheet_copies_url
    assert_select "tbody tr", count: 2
    assert_select "nav a[aria-current=page]", text: "Copias del spreadsheet"

    get rails_blob_path(copies.first.file, disposition: "attachment")
    follow_redirect!
    assert_response :success
    assert_equal spreadsheet_content, response.body.b
    assert_includes response.headers["Content-Disposition"], "attachment"
  end

  test "failed downloads preserve earlier copies" do
    existing = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    [ [ "503 Service Unavailable", "Unavailable" ], [ "200 OK", "<html>Sign in</html>" ], [ "200 OK", "" ] ].each do |status, body|
      with_spreadsheet_response(body: body, status: status) do
        assert_no_difference [ "SpreadsheetCopy.count", "ActiveStorage::Blob.count" ] do
          post spreadsheet_copies_url
        end
      end
      follow_redirect!
      assert_select "[role=alert]", text: /No se pudo descargar/
      assert_select "tbody tr", count: 1
    end

    assert_equal spreadsheet_content, existing.file.download
  end
end

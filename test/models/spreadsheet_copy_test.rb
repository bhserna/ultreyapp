require "test_helper"
require_relative "../support/spreadsheet_server"

class SpreadsheetCopyTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  include SpreadsheetServer

  test "order copies by download time and descending ID to select the latest" do
    copies = [ Time.utc(2026, 11, 14), Time.utc(2026, 11, 14), Time.utc(2026, 11, 13) ].map do |created_at|
      SpreadsheetCopy.create!(created_at: created_at, file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    end

    assert_equal [ copies[1], copies[0], copies[2] ], SpreadsheetCopy.newest_first.to_a
    assert_equal copies[1], SpreadsheetCopy.latest
  end

  test "return no latest copy when none have been downloaded" do
    assert_nil SpreadsheetCopy.latest
  end

  test "each download saves the original file in a separate copy" do
    copies = with_spreadsheet_response(body: spreadsheet_content) do
      Array.new(2) do
        copy = nil
        assert_difference "SpreadsheetCopy.count", 1 do
          copy = SpreadsheetCopy.download!
        end
        copy
      end
    end

    copies.each do |copy|
      assert_equal spreadsheet_content, copy.file.download
      assert_equal SpreadsheetCopy::CONTENT_TYPE, copy.file.content_type
    end
    assert_not_equal copies.first.file.blob_id, copies.last.file.blob_id
  end

  {
    "HTTP error" => [ "503 Service Unavailable", "Unavailable" ],
    "HTML response" => [ "200 OK", "<html>Sign in</html>" ],
    "empty response" => [ "200 OK", "" ]
  }.each do |description, (status, body)|
    test "a download with #{description} preserves earlier copies without saving a new file" do
      existing = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

      with_spreadsheet_response(body: body, status: status) do
        assert_no_difference [ "SpreadsheetCopy.count", "ActiveStorage::Blob.count", "ActiveStorage::Attachment.count" ] do
          assert_raises SpreadsheetCopy::DownloadError do
            SpreadsheetCopy.download!
          end
        end
      end

      assert_equal spreadsheet_content, existing.reload.file.download
    end
  end
end

require "test_helper"
require "zip"

class OfflineDownloadsTest < ActionDispatch::IntegrationTest
  include ActionDispatch::TestProcess::FixtureFile

  test "download exports the requested copy in full regardless of filters" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_prior_activities.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    SpreadsheetCopy.create!(file: fixture_file_upload("program.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    document = Document.create!(spreadsheet_act_key: "act-002", file: fixture_file_upload("agenda.txt", "text/plain"))

    get spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "acts")
    assert_select "a[href=?][data-turbo=false]", spreadsheet_copy_offline_download_path(copy), text: "Descargar para usar sin internet"

    get spreadsheet_copy_offline_download_path(copy), params: { day: "Domingo 15", row_type: "acts" }

    assert_response :success
    assert_equal "application/zip", response.media_type
    assert_includes response.headers["Content-Disposition"], "ultreyapp-#{copy.id}-offline.zip"
    Zip::File.open_buffer(response.body) do |zip|
      index = zip.read("index.html").force_encoding(Encoding::UTF_8)
      assert_includes index, "Sábado 14"
      assert_includes index, "Copia sin conexión"
      assert_equal file_fixture("agenda.txt").binread, zip.read("documents/#{document.id}-agenda.txt")
    end
  end

  test "unreadable spreadsheet offers the saved copy instead of a broken download" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("spreadsheet.xlsx", SpreadsheetCopy::CONTENT_TYPE))

    get spreadsheet_copy_offline_download_path(copy)

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_select "[role=alert]", text: /No se pudo mostrar el programa/
  end

  test "missing attachment returns to the program without an incomplete zip" do
    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_renamed_sheets.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    document = Document.create!(spreadsheet_act_key: "act-002", file: fixture_file_upload("agenda.txt", "text/plain"))
    document.file.blob.service.delete(document.file.blob.key)

    get spreadsheet_copy_offline_download_path(copy)

    assert_redirected_to spreadsheet_copy_program_path(copy)
    assert_match /falta un documento adjunto/, flash[:alert]
  end

  test "unknown copy cannot be downloaded" do
    get spreadsheet_copy_offline_download_path(spreadsheet_copy_id: -1)

    assert_response :not_found
  end
end

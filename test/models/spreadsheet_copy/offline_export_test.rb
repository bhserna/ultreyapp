require "test_helper"
require "zip"

class SpreadsheetCopy::OfflineExportTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "export includes every page, local styles and only unambiguous program documents" do
    copy = create_copy("program_prior_activities.xlsx")
    program = copy.program
    document = Document.create!(spreadsheet_act_key: "act-002", file: fixture_file_upload("agenda.txt", "text/plain"))
    Document.create!(spreadsheet_act_key: "removed-act", file: fixture_file_upload("participants.csv", "text/csv"))
    Document.create!(act_id: 999, file: fixture_file_upload("agenda.txt", "text/plain"))

    with_export(copy) do |zip|
      assert zip.find_entry("index.html")
      assert_includes zip.read("assets/application.css"), "@layer"
      program.days.each do |day|
        assert zip.find_entry(copy.offline_export.day_path(day))
        program.entries(day: day).each do |entry|
          html = zip.read(copy.offline_export.entry_path(entry)).force_encoding(Encoding::UTF_8)
          assert_includes html, ERB::Util.html_escape(entry.title)
        end
      end
      assert_equal [ "documents/#{document.id}-agenda.txt" ], zip.entries.map(&:name).grep(%r{\Adocuments/})
      assert_equal file_fixture("agenda.txt").binread, zip.read("documents/#{document.id}-agenda.txt")
      assert_local_links(zip)
    end
  end

  test "document filenames are safe local paths and cannot collide" do
    copy = create_copy("program_renamed_sheets.xlsx")
    first = Document.create!(spreadsheet_act_key: "act-002", file: {
      io: StringIO.new("first"), filename: "Guía #1?%.txt", content_type: "text/plain"
    })
    second = Document.create!(spreadsheet_act_key: "act-002", file: {
      io: StringIO.new("second"), filename: "Guía #1?%.txt", content_type: "text/plain"
    })

    with_export(copy) do |zip|
      export = copy.offline_export
      refute_equal export.document_path(first), export.document_path(second)
      assert_equal "first", zip.read(export.document_path(first))
      assert_equal "second", zip.read(export.document_path(second))
      assert_match %r{\Adocuments/[a-zA-Z0-9._-]+\z}, export.document_path(first)
      assert_local_links(zip)
    end
  end

  test "duplicate act IDs do not export ambiguous documents" do
    copy = create_copy("program_duplicate_ids.xlsx")
    Document.create!(spreadsheet_act_key: "act-002", file: fixture_file_upload("agenda.txt", "text/plain"))

    with_export(copy) do |zip|
      assert_empty zip.entries.map(&:name).grep(%r{\Adocuments/})
      assert_local_links(zip)
    end
  end

  test "missing document files fail the export instead of producing an incomplete copy" do
    copy = create_copy("program_renamed_sheets.xlsx")
    document = Document.create!(spreadsheet_act_key: "act-002", file: fixture_file_upload("agenda.txt", "text/plain"))
    document.file.blob.service.delete(document.file.blob.key)

    assert_raises ActiveStorage::FileNotFoundError do
      with_export(copy) { flunk "Export must not succeed" }
    end
  end

  private

  def create_copy(filename)
    SpreadsheetCopy.create!(file: fixture_file_upload(filename, SpreadsheetCopy::CONTENT_TYPE))
  end

  def with_export(copy)
    Tempfile.create([ "offline-test", ".zip" ]) do |file|
      copy.offline_export.write_to(file.path)
      Zip::File.open(file.path) { |zip| yield zip }
    end
  end

  def assert_local_links(zip)
    zip.entries.select { |entry| entry.name.end_with?(".html") }.each do |entry|
      html = Nokogiri::HTML(zip.read(entry.name))
      assert_empty html.css("script, turbo-frame, form")
      html.css("[href], [src]").each do |element|
        target = element["href"] || element["src"]
        assert zip.find_entry(target), "Missing local target #{target} in #{entry.name}"
      end
    end
  end
end

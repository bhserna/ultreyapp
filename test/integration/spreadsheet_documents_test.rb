require "test_helper"
require "active_record/testing/query_assertions"

class SpreadsheetDocumentsIntegrationTest < ActionDispatch::IntegrationTest
  include ActiveRecord::Assertions::QueryAssertions

  test "render document indicators with one grouped query and only for acts with files" do
    copy = create_copy("program_renamed_sheets.xlsx")
    create_document("act-001", "agenda.txt")
    create_document("act-002", "agenda.txt")
    create_document("act-002", "participants.csv")
    create_document("act-005", "participants.csv")
    create_document("unknown-act", "agenda.txt")
    Document.create!(act_id: activities(:opening_act).id, file: fixture_file_upload("agenda.txt", "text/plain"))

    assert_queries_match(/FROM "documents"/, count: 1) do
      get spreadsheet_copy_day_path(copy, "Domingo 15")
    end
    assert_response :success
    assert_select "[role=img]", count: 2
    assert_select "[role=img][aria-label='1 documento']", text: "1"
    assert_select "[role=img][aria-label='2 documentos']", text: "2"
    assert_select "a [role=img], button [role=img]", count: 0
    assert_select "[role=img][aria-label='0 documentos']", count: 0
    assert_select "tr", text: /Grupo Folklórico/ do
      assert_select "[role=img]", count: 0
    end

    get spreadsheet_copy_day_path(copy, "Domingo 15", row_type: "preparations")
    assert_select "td strong", text: "Preparación", minimum: 1
    assert_select "[role=img]", count: 0

    get spreadsheet_copy_day_path(copy, "Lunes 16", row_type: "acts")
    assert_select "[role=img]", count: 1
    assert_select "tr", text: /Bienvenida del lunes/ do
      assert_select "[role=img][aria-label='1 documento']", text: "1"
    end
  end

  test "upload uses the act ID from the copy rather than submitted references" do
    copy = create_copy("program_renamed_sheets.xlsx")
    files = [ fixture_file_upload("agenda.txt", "text/plain"), fixture_file_upload("participants.csv", "text/csv") ]

    assert_difference "Document.count", 2 do
      post spreadsheet_copy_day_act_documents_path(copy, "Domingo 15", 2),
        params: { files: files, spreadsheet_act_key: "act-999", act_id: activities(:opening_act).id }
    end

    documents = Document.order(:id).last(2)
    documents.each do |document|
      assert_equal "act-002", document.spreadsheet_act_key
      assert_equal "Inicio / Video", document.spreadsheet_act_title
      assert_nil document.act_id
      assert_equal file_fixture(document.file.filename.to_s).binread, document.file.download
    end
  end

  test "download delivers the saved file and does not mix other acts or legacy documents" do
    copy = create_copy("program_renamed_sheets.xlsx")
    document = create_document("act-002", "agenda.txt")
    create_document("act-003", "participants.csv")
    Document.create!(act_id: activities(:opening_act).id, file: fixture_file_upload("participants.csv", "text/plain"))

    get spreadsheet_copy_day_act_documents_path(copy, "Domingo 15", 2)
    assert_select ".documents__file a", text: "agenda.txt"
    assert_select ".documents__file a", text: "participants.csv", count: 0
    get css_select(".documents__file a").sole["href"]
    follow_redirect!

    assert_response :success
    assert_equal document.file.download, response.body.b
    assert_includes response.headers["Content-Disposition"], "attachment"
  end

  test "deletion is scoped to the stable key and purges only that document" do
    copy = create_copy("program_renamed_sheets.xlsx")
    document = create_document("act-002", "agenda.txt")
    other = create_document("act-003", "participants.csv")
    original = other.file.download
    blob = document.file.blob

    assert_no_difference [ "Document.count", "ActiveStorage::Blob.count" ] do
      delete spreadsheet_copy_day_act_document_path(copy, "Domingo 15", 2, other)
      assert_response :not_found
    end
    assert_equal original, other.reload.file.download

    assert_difference [ "Document.count", "ActiveStorage::Blob.count", "ActiveStorage::Attachment.count" ], -1 do
      delete spreadsheet_copy_day_act_document_path(copy, "Domingo 15", 2, document)
    end
    assert_not blob.service.exist?(blob.key)
    assert_equal original, other.reload.file.download
  end

  test "missing and duplicate IDs disable reads and writes without changing saved documents" do
    document = create_document("act-002", "agenda.txt")
    [ [ "program.xlsx", "no tiene ID" ], [ "program_duplicate_ids.xlsx", "está duplicado" ] ].each do |filename, message|
      copy = create_copy(filename)
      [ "Domingo 15", "Lunes 16" ].each do |day|
        get spreadsheet_copy_day_path(copy, day)
        assert_response :success
        assert_select "[role=img]", count: 0
      end
      path = spreadsheet_copy_day_act_documents_path(copy, "Domingo 15", 2)
      get path
      assert_select "[role=status]", text: /#{message}/
      assert_select "input[type=file]", count: 0
      assert_select ".documents__file", count: 0

      assert_no_difference [ "Document.count", "ActiveStorage::Blob.count" ] do
        post path, params: { files: [ fixture_file_upload("agenda.txt", "text/plain") ] }
        assert_response :not_found
        delete spreadsheet_copy_day_act_document_path(copy, "Domingo 15", 2, document)
        assert_response :not_found
      end
    end
    assert_equal file_fixture("agenda.txt").binread, document.reload.file.download
  end

  test "unassigned documents are compared against the latest copy without including legacy files" do
    create_copy("program_renamed_sheets.xlsx")
    create_document("act-003", "participants.csv")
    create_document("act-002", "agenda.txt")
    Document.create!(act_id: activities(:opening_act).id, file: fixture_file_upload("agenda.txt", "text/plain"))
    create_copy("program_document_updates.xlsx")

    get spreadsheet_documents_path

    assert_select "tbody tr", count: 1
    assert_select "tbody td", text: "act-003"
    assert_select "tbody a", text: "participants.csv"
    assert_equal 3, Document.count
  end

  test "an unreadable latest copy does not falsely report documents as unassigned" do
    create_document("act-002", "agenda.txt")
    create_copy("spreadsheet.xlsx")

    get spreadsheet_documents_path

    assert_select "[role=alert]", text: /No se pudieron comprobar/
    assert_select "tbody", count: 0
    assert_select "p", text: "No hay documentos sin acto.", count: 0
    assert_equal 1, Document.count
  end

  private

  def create_copy(filename)
    SpreadsheetCopy.create!(file: fixture_file_upload(filename, SpreadsheetCopy::CONTENT_TYPE))
  end

  def create_document(key, filename)
    Document.create!(spreadsheet_act_key: key, spreadsheet_act_title: "Acto #{key}", file: fixture_file_upload(filename, "text/plain"))
  end
end

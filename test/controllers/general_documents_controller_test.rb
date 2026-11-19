require "test_helper"

class GeneralDocumentsControllerTest < ActionDispatch::IntegrationTest
  test "uploads are general regardless of submitted act references or scope" do
    assert_difference "Document.count", 2 do
      post general_documents_url, params: {
        files: [ fixture_file_upload("agenda.txt", "text/plain"), fixture_file_upload("participants.csv", "text/csv") ],
        scope: "act", act_id: 123, spreadsheet_act_key: "act-001"
      }
    end

    assert_redirected_to general_documents_url
    Document.order(:id).last(2).each do |document|
      assert document.scope_general?
      assert_nil document.spreadsheet_act_key
      assert document.file.attached?
    end
  end

  test "list only general documents" do
    general = create_document(scope: "general", filename: "agenda.txt")
    create_document(spreadsheet_act_key: "removed-act", filename: "participants.csv")

    get general_documents_url

    assert_response :success
    assert_select ".documents__file a", text: general.file.filename.to_s
    assert_select ".documents__file a", text: "participants.csv", count: 0
  end

  test "cannot delete act documents through the general documents page" do
    [ "act-001", "removed-act" ].each do |key|
      document = create_document(spreadsheet_act_key: key)
      content = document.file.download

      assert_no_difference [ "Document.count", "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ] do
        delete general_document_url(document)
        assert_response :not_found
      end

      assert_equal content, document.reload.file.download
    end
  end

  test "purge a deleted general document without changing other documents" do
    document = create_document(scope: "general")
    other = create_document(scope: "general")
    blob = document.file.blob
    other_content = other.file.download

    assert_difference [ "Document.count", "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ], -1 do
      delete general_document_url(document)
    end

    assert_redirected_to general_documents_url
    assert_not Document.exists?(document.id)
    assert_not blob.service.exist?(blob.key)
    assert_equal other_content, other.reload.file.download
  end

  private

  def create_document(filename: "agenda.txt", **attributes)
    Document.create!(**attributes, file: fixture_file_upload(filename, "text/plain"))
  end
end

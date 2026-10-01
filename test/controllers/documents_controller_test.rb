require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  test "uploads multiple documents and shows their formats" do
    get schedule_entry_url(3)
    assert_select "turbo-frame#documents[src=?]", schedule_entry_documents_path(3)

    files = [
      fixture_file_upload(Rails.root.join("test/fixtures/files/agenda.txt"), "text/plain"),
      fixture_file_upload(Rails.root.join("test/fixtures/files/participants.csv"), "text/csv")
    ]

    assert_difference("Document.count", 2) do
      post schedule_entry_documents_url(3), params: { files: files }
    end
    assert_redirected_to schedule_entry_documents_url(3)
    assert_equal [3], Document.distinct.pluck(:schedule_entry_id)

    get schedule_entry_documents_url(3)
    assert_response :success
    assert_select "turbo-frame#documents .documents__item", count: 2
    assert_select ".documents__format[data-format='txt']", text: "TXT"
    assert_select ".documents__format[data-format='csv']", text: "CSV"
    assert_select ".documents__file a", text: "agenda.txt"
    assert_select ".documents__file a", text: "participants.csv"
  end

  test "keeps documents scoped to their activity and deletes their files" do
    document = Document.create!(
      schedule_entry_id: 3,
      file: fixture_file_upload(Rails.root.join("test/fixtures/files/agenda.txt"), "text/plain")
    )
    blob_id = document.file.blob.id

    get schedule_entry_documents_url(4)
    assert_select ".documents__item", count: 0

    delete schedule_entry_document_url(4, document)
    assert_response :not_found
    assert Document.exists?(document.id)

    assert_difference("Document.count", -1) do
      delete schedule_entry_document_url(3, document)
    end
    assert_redirected_to schedule_entry_documents_url(3)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end
end

require "application_request_test_case"

class DocumentsControllerTest < ApplicationRequestTestCase
  test "upload under the act in the URL" do
    act = activities(:opening_act)
    file = fixture_file_upload(Rails.root.join("test/fixtures/files/agenda.txt"), "text/plain")

    assert_difference "Document.count", 1 do
      post schedule_entry_documents_url(act), params: { files: [ file ], act_id: activities(:closing_act).id }
    end

    document = Document.order(:id).last
    assert_equal act.id, document.act_id
    assert document.file.attached?
    assert_redirected_to schedule_entry_documents_url(act)
  end

  test "list only the act documents" do
    act = activities(:opening_act)
    document = create_document(act, "agenda.txt")
    other_document = create_document(activities(:closing_act), "participants.csv")

    get schedule_entry_documents_url(act)

    assert_response :success
    assert_select ".documents__file a", text: document.file.filename.to_s
    assert_select ".documents__file a", text: other_document.file.filename.to_s, count: 0
  end

  test "reject deletion through another act" do
    document = create_document(activities(:opening_act), "agenda.txt")
    original_attributes = document.reload.attributes
    attachment = document.file.attachment
    blob = document.file.blob
    original_content = document.file.download

    assert_no_difference [ "Document.count", "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ] do
      delete schedule_entry_document_url(activities(:closing_act), document)
      assert_response :not_found
    end

    assert_equal original_attributes, document.reload.attributes
    assert_equal attachment.id, document.file.attachment.id
    assert_equal blob.id, document.file.blob.id
    assert_equal original_content, document.file.download
  end

  test "purge the deleted document file" do
    act = activities(:opening_act)
    document = create_document(act, "agenda.txt")
    other_document = create_document(act, "participants.csv")
    blob = document.file.blob
    attachment_id = document.file.attachment.id
    other_attributes = other_document.reload.attributes
    other_content = other_document.file.download

    assert_difference [ "Document.count", "ActiveStorage::Attachment.count", "ActiveStorage::Blob.count" ], -1 do
      delete schedule_entry_document_url(act, document)
    end

    assert_redirected_to schedule_entry_documents_url(act)
    assert_not Document.exists?(document.id)
    assert_not ActiveStorage::Attachment.exists?(attachment_id)
    assert_not ActiveStorage::Blob.exists?(blob.id)
    assert_not blob.service.exist?(blob.key)
    assert_equal other_attributes, other_document.reload.attributes
    assert_equal other_content, other_document.file.download
  end

  private

  def create_document(act, filename)
    Document.create!(act_id: act.id, file: fixture_file_upload(Rails.root.join("test/fixtures/files", filename), "text/plain"))
  end
end

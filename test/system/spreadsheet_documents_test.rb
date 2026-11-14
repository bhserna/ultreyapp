require "application_system_test_case"

class SpreadsheetDocumentsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "upload multiple documents and share them across reordered copies of the same act" do
    original = create_copy("program_renamed_sheets.xlsx")
    visit spreadsheet_copy_day_act_path(original, "Domingo 15", 2, row_type: "acts")

    within "turbo-frame#documents" do
      attach_file "files[]", [ file_fixture("agenda.txt"), file_fixture("participants.csv") ]
      assert_link "agenda.txt"
      assert_link "participants.csv"
    end

    updated = create_copy("program_document_updates.xlsx")
    visit current_program_path
    within "tr", text: "Inicio corregido" do
      click_link "Ver detalle"
    end
    assert_current_path spreadsheet_copy_day_act_path(updated, "Domingo 15", 1)
    within "turbo-frame#documents" do
      assert_link "agenda.txt"
      assert_link "participants.csv"
      within "li", text: "agenda.txt" do
        accept_confirm { click_button "Eliminar" }
      end
      assert_no_link "agenda.txt"
      assert_link "participants.csv"
    end

    visit spreadsheet_copy_day_act_path(original, "Domingo 15", 2, row_type: "acts")
    within "turbo-frame#documents" do
      assert_link "participants.csv"
      assert_no_link "agenda.txt"
    end
    click_link "← Volver al programa"
    assert_current_path spreadsheet_copy_day_path(original, "Domingo 15", row_type: "acts")
  end

  test "files from a removed act remain downloadable in documents without an act" do
    copy = create_copy("program_renamed_sheets.xlsx")
    visit spreadsheet_copy_day_act_path(copy, "Domingo 15", 3)
    within "turbo-frame#documents" do
      attach_file "files[]", file_fixture("agenda.txt")
      assert_link "agenda.txt"
    end

    create_copy("program_document_updates.xlsx")
    visit spreadsheet_copies_path
    click_link "Documentos sin acto"

    assert_selector "h1", text: "Documentos sin acto"
    assert_text "act-003"
    assert_text "Grupo Folklórico"
    assert_link "agenda.txt"
  end

  test "missing and duplicate IDs explain why documents cannot be attached" do
    copy = create_copy("program.xlsx")
    visit spreadsheet_copy_day_act_path(copy, "Domingo 15", 2)
    within "turbo-frame#documents" do
      assert_text "Este acto no tiene ID"
      assert_no_selector "input[type=file]"
    end

    copy = create_copy("program_duplicate_ids.xlsx")
    Document.create!(spreadsheet_act_key: "act-002", file: fixture_file_upload("agenda.txt", "text/plain"))
    visit spreadsheet_copy_day_act_path(copy, "Domingo 15", 2)
    within "turbo-frame#documents" do
      assert_text "El ID de este acto está duplicado"
      assert_no_selector "input[type=file]"
      assert_no_link "agenda.txt"
    end

    visit spreadsheet_documents_path
    assert_text "act-002"
    assert_link "agenda.txt"
  end

  private

  def create_copy(filename)
    SpreadsheetCopy.create!(file: fixture_file_upload(filename, SpreadsheetCopy::CONTENT_TYPE))
  end
end

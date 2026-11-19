require "application_system_test_case"

class GeneralDocumentsTest < ApplicationSystemTestCase
  include ActionDispatch::TestProcess::FixtureFile

  test "navigate to general documents, upload multiple files and delete one" do
    visit root_path
    click_link "Documentos generales"

    assert_selector "h1", text: "Documentos generales"
    assert_text "Todavía no hay documentos generales."

    within("turbo-frame#documents") do
      attach_file "files[]", [
        Rails.root.join("test/fixtures/files/agenda.txt"),
        Rails.root.join("test/fixtures/files/participants.csv")
      ]

      assert_text "agenda.txt"
      assert_text "participants.csv"

      within("li", text: "agenda.txt") do
        accept_confirm { click_button "Eliminar" }
      end

      assert_no_text "agenda.txt"
      assert_text "participants.csv"
    end

    copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_renamed_sheets.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    visit spreadsheet_copy_day_act_path(copy, "Domingo 15", 2)
    within("turbo-frame#documents") do
      assert_no_text "participants.csv"
    end

    visit general_documents_path
    assert_text "participants.csv"
  end
end

require "application_system_test_case"

class GeneralDocumentsTest < ApplicationSystemTestCase
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

    visit schedule_entry_path(activities(:opening_act))
    within("turbo-frame#documents") do
      assert_no_text "participants.csv"
    end

    visit general_documents_path
    assert_text "participants.csv"
  end
end

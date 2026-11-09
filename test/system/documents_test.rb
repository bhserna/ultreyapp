require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  test "upload and delete documents" do
    visit schedule_entry_path(activities(:opening_act))

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
  end
end

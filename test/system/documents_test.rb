require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  test "uploads and deletes documents from an activity" do
    visit root_path(day: "Domingo 15")

    within("tr", text: "Instalación de stands") do
      click_link "Preguntas y documentos"
    end

    assert_text "Instalación de stands"

    within("turbo-frame#documents") do
      attach_file "files[]", [
        Rails.root.join("test/fixtures/files/agenda.txt"),
        Rails.root.join("test/fixtures/files/participants.csv")
      ]

      assert_text "agenda.txt"
      assert_text "participants.csv"
      assert_selector ".documents__format[data-format='txt']", text: "TXT"
      assert_selector ".documents__format[data-format='csv']", text: "CSV"

      within("li", text: "agenda.txt") do
        accept_confirm { click_button "Eliminar" }
      end

      assert_no_text "agenda.txt"
      assert_text "participants.csv"
    end
  end
end

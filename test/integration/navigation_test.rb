require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "main navigation links to the current program, spreadsheet copies and general documents" do
    get spreadsheet_copies_path

    assert_response :success
    assert_select "nav[aria-label='Navegación principal']" do
      assert_select "a", count: 3
      assert_select "a[href=?]", current_program_path, text: "Programa actualizado"
      assert_select "a[href=?]", spreadsheet_copies_path, text: "Copias del spreadsheet"
      assert_select "a[href=?]", general_documents_path, text: "Documentos generales"
    end
  end
end

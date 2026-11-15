require "test_helper"

class NavigationTest < ActionDispatch::IntegrationTest
  test "main navigation only links to the current program and spreadsheet copies" do
    get spreadsheet_copies_path

    assert_response :success
    assert_select "nav[aria-label='Navegación principal']" do
      assert_select "a", count: 2
      assert_select "a[href=?]", current_program_path, text: "Programa actualizado"
      assert_select "a[href=?]", spreadsheet_copies_path, text: "Copias del spreadsheet"
    end
  end
end

require "test_helper"

class SpreadsheetEntryDetailsTest < ActionView::TestCase
  test "details preserve basic formatting and line breaks without HTML wrappers" do
    render_details("<html>Primera línea\n<b>Negrita</b> <strong>Importante</strong> <i>Cursiva</i> <em>Énfasis</em><br>Final</html>")

    assert_select "b", text: "Negrita"
    assert_select "strong", text: "Importante"
    assert_select "i", text: "Cursiva"
    assert_select "em", text: "Énfasis"
    assert_select "br", minimum: 2
    assert_includes rendered, "Primera línea"
    assert_not_includes rendered, "&lt;html&gt;"
    assert_not_includes rendered, "<html>"
  end

  test "details remove unsafe elements and all source attributes" do
    render_details('<b onclick="alert(1)" style="color:red" class="source">Texto seguro</b><script>alert(1)</script><img src="x" onerror="alert(1)"><a href="javascript:alert(1)">Enlace</a>')

    assert_select "b", text: "Texto seguro"
    assert_select "script, img, a, [onclick], [onerror], [style], [class]", count: 0
    assert_not_includes rendered, "&lt;script"
  end

  private

  def render_details(text)
    entry = SpreadsheetCopy::Act.new(day: "Domingo 15", position: 1, number: "4", schedule: "10:00", title: "Acto", screen: text)
    render partial: "shared/spreadsheet_entry_details", locals: { entry: entry, fields: { screen: "Video / Pantalla" } }
  end
end

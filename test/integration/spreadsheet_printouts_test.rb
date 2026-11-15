require "test_helper"

class SpreadsheetPrintoutsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_prior_activities.xlsx", SpreadsheetCopy::CONTENT_TYPE))
  end

  test "all days include the same ordered entries in their table and details" do
    get spreadsheet_copy_printout_path(@copy)
    assert_response :success

    program = @copy.program
    assert_select ".printout__day", count: program.days.size
    program.days.each do |day|
      entries = program.entries(day: day)
      assert_select ".printout__day[aria-label=?]", day do
        assert_select "tbody tr", count: entries.size
        assert_select "article h2" do |headings|
          assert_equal entries.map(&:title), headings.map(&:text)
        end
        assert_select "tbody tr td:last-child" do |cells|
          assert_equal entries.map(&:title), cells.map(&:text)
        end
      end
    end
    assert_select "turbo-frame, input[type=file]", count: 0
    assert_select "a", text: "Ver detalle", count: 0
  end

  test "prior activity details preserve basic formatting and omit empty fields" do
    get spreadsheet_copy_printout_path(@copy, day: "Sábado 14", row_type: "prior_activities")
    assert_response :success
    assert_select "article", count: @copy.program.entries(day: "Sábado 14", row_type: "prior_activities").size
    assert_select "article h3", text: "Responsables"
    assert_select "article p", text: /Al menos uno por comisión sin bloquear\./
    assert_select "article b", text: "sin bloquear"
    assert_select "article p br"
  end

  test "act details and empty selections" do
    detailed_copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    get spreadsheet_copy_printout_path(detailed_copy, day: "Domingo 15", row_type: "acts")
    assert_response :success
    assert_select "article h3", text: "Audio"
    assert_select "article .page__eyebrow", text: /Actividad previa/, count: 0

    get spreadsheet_copy_printout_path(@copy, day: "Sábado 14", row_type: "acts")
    assert_response :success
    assert_select "td", text: "No hay actividades de este tipo para este día."
    assert_select "article", count: 0
  end

  test "invalid days and copies return not found while unknown types are ignored" do
    get spreadsheet_copy_printout_path(@copy, day: "Unknown")
    assert_response :not_found
    get spreadsheet_copy_printout_path(SpreadsheetCopy.maximum(:id) + 1)
    assert_response :not_found
    get spreadsheet_copy_printout_path(@copy, day: "Sábado 14", row_type: "unknown", include_details: "0")
    assert_response :success
    assert_select "table", text: /Recepción de Diócesis/
    assert_select "article", count: 0
  end
end

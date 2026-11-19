require "test_helper"

class SpreadsheetPrintoutsIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_prior_activities.xlsx", SpreadsheetCopy::CONTENT_TYPE))
  end

  test "all days include ordered entries with details inside the activity cell without duplicate headings" do
    get spreadsheet_copy_printout_path(@copy)
    assert_response :success

    program = @copy.program
    assert_select ".printout__day", count: program.days.size
    program.days.each do |day|
      entries = program.entries(day: day)
      assert_select ".printout__day[aria-label=?]", day do
        assert_select "tbody tr", count: entries.size
        assert_select "article, h3, .page__eyebrow", count: 0
        assert_select "thead th" do |headers|
          assert_equal [ "Horario", "Acto", "Actividad" ], headers.map(&:text)
        end
        assert_select "tbody tr" do |rows|
          entries.zip(rows).each do |entry, row|
            assert_select row, "td", count: 3
            assert_select row, "td:last-child .printout__title" do |cells|
              cell = cells.sole
              if entry.is_a?(SpreadsheetCopy::Act)
                assert_select cell, "strong", count: 0
                assert_equal entry.title, cell.text.squish
              else
                type = entry.is_a?(SpreadsheetCopy::Preparation) ? "Preparación" : "Actividad previa"
                assert_select cell, "strong", text: type
                assert_equal "#{type} · #{entry.title}", cell.text.squish
              end
            end
            fields = spreadsheet_entry_fields(entry)
            labels = row.css("td:last-child .printout__details dt")
            assert_equal fields.map { |attribute, label| "#{label}:" }, labels.map(&:text)
            fields.each do |attribute, label|
              assert_select row, "td:last-child .printout__details dd", text: /#{Regexp.escape(ApplicationController.helpers.strip_tags(entry.public_send(attribute)).squish)}/
            end
          end
        end
      end
    end
    assert_select "turbo-frame, input[type=file]", count: 0
    assert_select "a", text: "Ver detalle", count: 0
  end

  test "prior activity details preserve basic formatting and omit empty fields" do
    get spreadsheet_copy_printout_path(@copy, day: "Sábado 14", row_type: "prior_activities")
    assert_response :success
    assert_select "td .printout__details dt", text: "Responsables:"
    assert_select "td .printout__details p", text: /Al menos uno por comisión sin bloquear\./
    assert_select "td .printout__details b", text: "sin bloquear"
    assert_select "td .printout__details p br"
    assert_select ".printout__details dt", text: "Pendientes:", count: 0
  end

  test "act details and empty selections" do
    detailed_copy = SpreadsheetCopy.create!(file: fixture_file_upload("program_details.xlsx", SpreadsheetCopy::CONTENT_TYPE))
    get spreadsheet_copy_printout_path(detailed_copy, day: "Domingo 15", row_type: "acts")
    assert_response :success
    assert_select "td .printout__details dt", text: "Audio:"
    assert_select ".printout__title strong", text: "Actividad previa", count: 0

    get spreadsheet_copy_printout_path(@copy, day: "Sábado 14", row_type: "acts")
    assert_response :success
    assert_select "td[colspan='3']", text: "No hay actividades de este tipo para este día."
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
    assert_select "article, .printout__details", count: 0
  end

  private

  def spreadsheet_entry_fields(entry)
    helpers = ApplicationController.helpers
    helpers.spreadsheet_entry_detail_fields(entry).select { |attribute, label| entry.public_send(attribute).present? }
  end
end

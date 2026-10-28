require "test_helper"
require_relative "../support/response_html_assertions"

class ScheduleControllerTest < ActionDispatch::IntegrationTest
  include ResponseHtmlAssertions

  test "shows Sunday table columns and activity details" do
    get root_url

    assert_response :success
    assert_select "h1", text: "Programa"
    assert_select "nav[aria-label='Días del programa'] a", count: 3
    assert_select "nav a[aria-current='page']", text: "Domingo 15"
    assert_select "nav a[href=?]", root_path(day: "Lunes 16"), text: "Lunes 16"
    assert_select "select#commission option[value='Programa']", text: "Programa"
    assert_select "thead th", count: 7
    assert_select "thead th:nth-child(1)", text: "Acto"
    assert_select "thead th:nth-child(2)", text: "Hora Inicio"
    assert_select "thead th:nth-child(3)", text: "Hora Fin"
    assert_select "thead th:nth-child(4)", text: "Duración"
    assert_select "thead th:nth-child(5)", text: "Actividad"
    assert_select "thead th:nth-child(6)", text: "Comisión"
    assert_select "thead th:nth-child(7) .visually-hidden", text: "Preguntas y documentos"
    assert_select "tbody tr.schedule__act", count: 19
    assert_select "tbody tr.schedule__preparation", count: 17
    assert_select "tbody tr.schedule__act", text: /Proyección Video Inicio/ do
      assert_select "td:nth-child(1)", text: "1"
      assert_select "td:nth-child(2)", text: "10:00"
      assert_select "td:nth-child(3)", text: "10:05"
      assert_select "td:nth-child(4)", text: "0:05"
      assert_select "td:nth-child(5)", text: /Proyección Video Inicio/
      assert_select "td:nth-child(6) .commission-links", text: "Programa"
      assert_select "td:nth-child(7) a[href=?]", schedule_entry_path(1), text: "Ver detalle"
    end
    assert_select "tbody tr.schedule__operation", count: 11
    assert_select "tbody tr.schedule__operation", text: /Instalación de stands/
    assert_select "tbody td", text: "Recepción de Diócesis", count: 0
    assert_no_match(/Se finalizan las actividades previas/, response.body)
  end

  test "shows Monday acts and preparations when its tab is selected" do
    get root_url(day: "Lunes 16")

    assert_response :success
    assert_select "nav a[aria-current='page']", text: "Lunes 16"
    assert_select "tbody tr.schedule__act", count: 12
    assert_select "tbody tr.schedule__preparation", count: 9
    within(:schedule_preparation, 18) do
      assert_selector :schedule_cell, :start_time, exact_text: "07:40"
      assert_selector :link, "Ver detalle", href: preparation_path(18)
    end
    assert_select "tbody tr.schedule__act td:nth-child(5)", text: "INICIO / Presentación de conductores / Bienvenida"
    assert_select "tbody tr.schedule__act td:nth-child(5)", text: "Desmontaje"
    assert_select "tbody tr:last-child[data-preparation-id='20'] td:nth-child(2)", text: "21:30"
    assert_select "tbody td", text: "Participación Gpo Folclórico", count: 0
  end

  test "renders schedule rows in the phases and order provided by the model on both days" do
    [ "Domingo 15", "Lunes 16" ].each do |day|
      get root_url(day: day)
      assert_response :success
      rows_by_phase = Schedule.new(day: day, commission: nil).rows.group_by(&:phase)

      within("table") do |table|
        assert_equal rows_by_phase.keys, table.all(:schedule_phase).map { |phase| phase["data-phase"] }
      end
      rows_by_phase.each do |phase, rows|
        within(:schedule_phase, phase) do |section|
          assert_selector "th[scope='rowgroup']", exact_text: Schedule::PHASES.fetch(phase)
          expected_paths = rows.map do |row|
            case row
            when Preparation then preparation_path(row.id)
            when OperationalActivity then operational_activity_path(row.id)
            else schedule_entry_path(row.id)
            end
          end
          rendered_paths = section.all(:schedule_row).map { |row| row.find(:link, "Ver detalle")[:href] }

          assert_equal expected_paths, rendered_paths, "Rows in #{phase} for #{day}"
        end
      end
    end
  end

  test "shows preparation start times without confusing them with action durations" do
    get root_url(day: "Domingo 15")

    within(:schedule_preparation, 2) do
      assert_selector :schedule_cell, :act_number, exact_text: "Preparación"
      assert_selector :schedule_cell, :activity, exact_text: "Preparación para el Acto 1 y 2"
      assert_selector :schedule_cell, :start_time, exact_text: "09:45"
      assert_selector :link, "Ver detalle", href: preparation_path(2)
    end
    within(:schedule_preparation, 7) do
      assert_selector :schedule_cell, :start_time, exact_text: "12:30"
      assert_no_selector :schedule_cell, :duration, text: "00:15"
    end
    within(:schedule_preparation, 12) do
      assert_selector :schedule_cell, :start_time, exact_text: "16:50"
    end
  end

  test "uses dashes for undecided times in the schedule table" do
    get root_url(day: "Domingo 15")

    assert_no_selector :schedule_cell, :start_time, text: "Por definir"
    assert_no_selector :schedule_cell, :end_time, text: "Por definir"
    within(:schedule_operation, 7) do
      assert_selector :schedule_cell, :start_time, exact_text: "—"
      assert_selector :schedule_cell, :end_time, exact_text: "08:00"
    end
    within(:schedule_operation, 12) do
      assert_selector :schedule_cell, :start_time, exact_text: "—"
      assert_selector :schedule_cell, :end_time, exact_text: "—"
    end
    within(:schedule_preparation, 1) do
      assert_selector :schedule_cell, :start_time, exact_text: "—"
    end
  end

  test "renders only phases that contain rows after filtering by activity type" do
    examples = [
      [ "Sábado 14", "operations", [ "pre_event" ] ],
      [ "Sábado 14", "acts", [] ],
      [ "Domingo 15", "acts", [ "program" ] ],
      [ "Domingo 15", "preparations", [ "before_parade", "program" ] ]
    ]

    examples.each do |day, row_type, expected_phases|
      get root_url(day: day, row_type: row_type)

      within("table") do |table|
        assert_equal expected_phases, table.all(:schedule_phase).map { |phase| phase["data-phase"] }, "Phases for #{row_type} on #{day}"
      end
    end
  end

  test "shows the official schedule times on both days" do
    get root_url(day: "Domingo 15")

    within(:schedule_act, "Presentación del Stmo y Entronización de la Virgen.") do
      assert_selector :schedule_cell, :act_number, exact_text: "4"
      assert_selector :schedule_cell, :start_time, exact_text: "10:50"
      assert_selector :schedule_cell, :end_time, exact_text: "11:50"
    end

    get root_url(day: "Lunes 16")

    within(:schedule_act, "Comida") do
      assert_selector :schedule_cell, :act_number, exact_text: "27"
      assert_selector :schedule_cell, :start_time, exact_text: "14:25"
      assert_selector :schedule_cell, :end_time, exact_text: "15:00"
      assert_selector :schedule_cell, :commission, exact_text: "Programa"
    end
  end

  test "filters acts by commission and preserves the filter across days" do
    get root_url(day: "Domingo 15", commission: "EyA")

    assert_response :success
    assert_select "select#commission option[selected][value='EyA']"
    assert_select "nav a[href=?]", root_path(day: "Lunes 16", commission: "EyA"), text: "Lunes 16"
    assert_select "tbody tr.schedule__act", count: 1
    assert_select "tbody tr.schedule__preparation", count: 4
    assert_selector :schedule_operation, count: 4
    assert_select "tbody tr.schedule__act td:nth-child(5)", text: "Canto de Colores"
    assert_select "tbody tr td:nth-child(6) a[href=?]", root_path(day: "Domingo 15", commission: "EyA"), text: "EyA"

    get root_url(day: "Lunes 16", commission: "EyA")

    assert_response :success
    assert_select "tbody tr td[colspan='7']", text: /No hay actividades de esta comisión/
    assert_select "tbody tr td:nth-child(5)", count: 0
  end

  test "renders the acts and preparations assigned to the program commission" do
    get root_url(day: "Domingo 15", commission: "Programa")

    assert_selector :schedule_act, count: 16
    assert_selector :schedule_preparation, count: 2
  end

  test "preserves type filters in day and commission links" do
    get root_url(day: "Domingo 15", row_type: "operations")

    assert_response :success
    assert_select "tbody tr.schedule__operation", count: 11
    assert_select "tbody tr.schedule__act", count: 0
    assert_select "tbody tr.schedule__preparation", count: 0
    assert_select "nav a[href=?]", root_path(day: "Sábado 14", row_type: "operations"), text: "Sábado 14"
    assert_select "tbody a[href=?]", root_path(day: "Domingo 15", commission: "Marketing", row_type: "operations"), text: "Marketing"

    get root_url(day: "Sábado 14", row_type: "acts")
    assert_select "tbody td[colspan='7']", text: "No hay actividades de este tipo para Sábado 14."
  end

  test "keeps detail links without resource counts for each act" do
    Question.create!(schedule_entry_id: 1, body: "Pendiente")
    Question.create!(schedule_entry_id: 1, body: "Contestada", answer: "Listo")
    blank = Question.create!(schedule_entry_id: 1, body: "Sin contenido")
    blank.update_column(:answer, "  \n  ")
    Document.create!(
      schedule_entry_id: 1,
      file: fixture_file_upload(Rails.root.join("test/fixtures/files/agenda.txt"), "text/plain")
    )

    get root_url

    assert_response :success
    assert_select ".schedule__resource-status", count: 0
    assert_select "tbody tr.schedule__act a[href=?]", schedule_entry_path(1), text: "Ver detalle"
    assert_select "tbody tr.schedule__act a[href=?]", schedule_entry_path(2), text: "Ver detalle"
    assert_no_match(/Preguntas \d+|Contestadas \d+|Documentos \d+/, response.body)

    get root_url(day: "Domingo 15", commission: "EyA")

    assert_response :success
    assert_select "tbody tr.schedule__act", count: 1
    assert_select ".schedule__resource-status", count: 0
    assert_select "tbody tr a[href=?]", schedule_entry_path(5), text: "Ver detalle"
  end
end

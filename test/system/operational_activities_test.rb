require "application_system_test_case"

class OperationalActivitiesTest < ApplicationSystemTestCase
  test "shows Saturday reception and kits with their own operational details" do
    visit root_path
    click_link "Sábado 14"

    assert_selector :schedule_operation, count: 2
    assert_no_selector :schedule_act
    assert_no_selector :schedule_preparation
    within(:schedule_operation, "Recepción de Diócesis") do
      assert_selector :schedule_cell, :start_time, text: "—"
      assert_selector ".schedule__category", text: "Recepción y atención a participantes"
      click_link "Ver detalle"
    end

    assert_selector "h1", text: "Recepción de Diócesis"
    assert_text "AC y Hosp, Parroquias y Centros"
    assert_text "Al menos uno por comisón"
    assert_text "Radios"
    assert_link "AC", href: root_path(day: "Sábado 14", commission: "AC")

    click_link "← Volver al programa"
    assert_current_path root_path(day: "Sábado 14")
    within(:schedule_operation, "Entrega de Kits") { click_link "Ver detalle" }
    assert_text "AC y Encargados de cada delegación"
    assert_text "se entregaran Kits y se realizan registros extemporaneos"
  end

  test "filters operations by commission across days without losing the row type" do
    visit root_path(day: "Domingo 15")
    select "Operación", from: "Tipo de actividad"
    assert_selector :schedule_operation, count: 11
    assert_no_selector :schedule_act
    assert_no_selector :schedule_preparation

    within(:schedule_operation, "Instalación de stands") { click_link "Marketing" }
    assert_selector :schedule_operation, count: 1
    assert_select "Tipo de actividad", selected: "Operación"
    assert_select "Comisión", selected: "Marketing"

    click_link "Sábado 14"
    assert_text "No hay actividades de esta comisión para Sábado 14."
    assert_select "Tipo de actividad", selected: "Operación"
    assert_select "Comisión", selected: "Marketing"

    select "Sin filtro de comisión", from: "Comisión"
    assert_selector :schedule_operation, count: 2
    assert_equal [ "Operación previa" ], schedule_phase_titles
    select "Actos", from: "Tipo de actividad"
    assert_no_selector :schedule_phase
    assert_text "No hay actividades de este tipo para Sábado 14."

    click_link "Domingo 15"
    assert_selector :schedule_act, count: 19
    assert_no_selector :schedule_operation
    assert_no_selector :schedule_preparation
    assert_equal [ "Programa del día" ], schedule_phase_titles
    select "Preparaciones", from: "Tipo de actividad"
    assert_selector :schedule_preparation, count: 17
    assert_no_selector :schedule_operation
    assert_no_selector :schedule_act
    assert_equal [ "Preparación previa al desfile", "Programa del día" ], schedule_phase_titles
    select "Todo", from: "Tipo de actividad"
    assert_selector :schedule_operation, count: 11
    assert_selector :schedule_act, count: 19
    assert_selector :schedule_preparation, count: 17
  end

  test "keeps undecided pre-event work and the pre-parade preparation before the program" do
    visit root_path(day: "Domingo 15")

    assert_no_text "Por definir"
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
    assert_equal [ "Operación previa", "Preparación previa al desfile", "Programa del día" ], schedule_phase_titles
    within(:schedule_phase, :pre_event) do
      assert_selector :schedule_operation, count: 11
      assert_equal [ "7", "12", "13" ], all(:schedule_operation).last(3).map { |row| row["data-operational-activity-id"] }
    end
    within(:schedule_phase, :before_parade) do
      assert_selector :schedule_preparation, 1
      assert_no_selector :schedule_operation
      assert_no_selector :schedule_act
    end
    within(:schedule_phase, :program) do
      assert_equal find(:schedule_preparation, 2), all(:schedule_row).first
      assert_no_selector :schedule_operation
      assert_equal "19:00", all(:schedule_preparation).last.find(:schedule_cell, :start_time).text
    end

    within(:schedule_operation, 7) { click_link "Ver detalle" }
    assert_text "Por definir con la Arena"
  end

  private

  def schedule_phase_titles
    all(:schedule_phase).map { |phase| phase.find("th").text }
  end
end

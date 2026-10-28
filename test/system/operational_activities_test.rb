require "application_system_test_case"

class OperationalActivitiesTest < ApplicationSystemTestCase
  test "shows Saturday reception and kits with their own operational details" do
    visit root_path
    click_link "Sábado 14"

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
    assert_selector :schedule_operation, "Instalación de stands"
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
    assert_selector :schedule_operation, "Recepción de Diócesis"
    select "Actos", from: "Tipo de actividad"
    assert_text "No hay actividades de este tipo para Sábado 14."

    click_link "Domingo 15"
    assert_selector :schedule_act, "Proyección Video Inicio"
    assert_no_selector :schedule_operation
    assert_no_selector :schedule_preparation

    select "Preparaciones", from: "Tipo de actividad"
    assert_selector :schedule_preparation, 2
    assert_no_selector :schedule_operation
    assert_no_selector :schedule_act

    select "Todo", from: "Tipo de actividad"
    assert_selector :schedule_operation, "Instalación de stands"
    assert_selector :schedule_act, "Proyección Video Inicio"
    assert_selector :schedule_preparation, 2
  end
end

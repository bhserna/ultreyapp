require "application_system_test_case"

class OperationalActivitiesTest < ApplicationSystemTestCase
  test "shows Saturday reception and kits with their own operational details" do
    visit root_path
    click_link "Sábado 14"

    assert_selector "tbody tr.schedule__operation", count: 2
    assert_no_selector "tbody tr.schedule__act, tbody tr.schedule__preparation"
    within("tr", text: "Recepción de Diócesis") do
      assert_selector "td:nth-child(2)", text: "—"
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
    within("tr", text: "Entrega de Kits") { click_link "Ver detalle" }
    assert_text "AC y Encargados de cada delegación"
    assert_text "se entregaran Kits y se realizan registros extemporaneos"
  end

  test "filters operations by commission across days without losing the row type" do
    visit root_path(day: "Domingo 15")
    select "Operación", from: "Tipo de actividad"
    assert_selector "tbody tr.schedule__operation", count: 11
    assert_no_selector "tbody tr.schedule__act, tbody tr.schedule__preparation"

    within("tr", text: "Instalación de stands") { click_link "Marketing" }
    assert_selector "tbody tr.schedule__operation", count: 1
    assert_equal "operations", find("#row_type").value
    assert_equal "Marketing", find("#commission").value

    click_link "Sábado 14"
    assert_text "No hay actividades de esta comisión para Sábado 14."
    assert_equal "operations", find("#row_type").value
    assert_equal "Marketing", find("#commission").value

    select "Sin filtro de comisión", from: "Comisión"
    assert_selector "tbody tr.schedule__operation", count: 2
    assert_equal ["Operación previa"], all("tr.schedule__phase th").map(&:text)
    select "Actos", from: "Tipo de actividad"
    assert_no_selector "tr.schedule__phase"
    assert_text "No hay actividades de este tipo para Sábado 14."

    click_link "Domingo 15"
    assert_selector "tbody tr.schedule__act", count: 19
    assert_no_selector "tbody tr.schedule__operation, tbody tr.schedule__preparation"
    assert_equal ["Programa del día"], all("tr.schedule__phase th").map(&:text)
    select "Preparaciones", from: "Tipo de actividad"
    assert_selector "tbody tr.schedule__preparation", count: 17
    assert_no_selector "tbody tr.schedule__operation, tbody tr.schedule__act"
    assert_equal ["Preparación previa al desfile", "Programa del día"], all("tr.schedule__phase th").map(&:text)
    select "Todo", from: "Tipo de actividad"
    assert_selector "tbody tr.schedule__operation", count: 11
    assert_selector "tbody tr.schedule__act", count: 19
    assert_selector "tbody tr.schedule__preparation", count: 17
  end

  test "keeps undecided pre-event work and the pre-parade preparation before the program" do
    visit root_path(day: "Domingo 15")

    assert_no_text "Por definir"
    within("tr[data-operational-activity-id='7']") do
      assert_selector "td:nth-child(2)", exact_text: "—"
      assert_selector "td:nth-child(3)", exact_text: "08:00"
    end
    within("tr[data-operational-activity-id='12']") do
      assert_selector "td:nth-child(2)", exact_text: "—"
      assert_selector "td:nth-child(3)", exact_text: "—"
    end
    within("tr[data-preparation-id='1']") do
      assert_selector "td:nth-child(2)", exact_text: "—"
    end
    assert_equal ["Operación previa", "Preparación previa al desfile", "Programa del día"], all("tr.schedule__phase th").map(&:text)
    within("tbody[data-phase='pre_event']") do
      assert_selector "tr.schedule__operation", count: 11
      assert_equal ["7", "12", "13"], all("tr.schedule__operation").last(3).map { |row| row["data-operational-activity-id"] }
    end
    within("tbody[data-phase='before_parade']") do
      assert_selector "tr[data-preparation-id='1']"
      assert_no_selector "tr.schedule__operation, tr.schedule__act"
    end
    within("tbody[data-phase='program']") do
      assert_selector "tr:nth-child(2)[data-preparation-id='2']"
      assert_no_selector "tr.schedule__operation"
      assert_equal "19:00", all("tr.schedule__preparation").last.find("td:nth-child(2)").text
    end

    within("tr[data-operational-activity-id='7']") { click_link "Ver detalle" }
    assert_text "Por definir con la Arena"
  end

  test "opens technical details and questions without assigning them to an act" do
    visit root_path(day: "Domingo 15", row_type: "operations")
    within("tr", text: "Preparación para la transmisión en vivo") { click_link "Ver detalle" }

    assert_selector "h1", text: "Preparación para la transmisión en vivo"
    assert_text "Servicios y proveedores"
    assert_text "07:00"
    assert_text "Proveedor externo (ANetwork)"
    assert_text "Con qué laptop o equipo se realizará la transmisión en vivo?"
    assert_text "ANetwork solo proporciona el enlace bidireccional de Internet."
    assert_no_selector "turbo-frame#questions, turbo-frame#documents"

    visit operational_activity_path(7)
    assert_text "Por definir con la Arena"
    assert_text "A qué hora puede ser la prueba de sonido e iluminación?"
    assert_no_text "Se finalizan las actividades previas"
  end
end

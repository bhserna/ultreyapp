require "test_helper"

class ScheduleControllerTest < ActionDispatch::IntegrationTest
  test "shows the first day on the home page" do
    get root_url

    assert_response :success
    assert_select "h1", text: "Programa"
    assert_select "nav[aria-label='Días del programa'] a", count: 3
    assert_select "nav a[aria-current='page']", text: "Sábado 14"
    assert_select "nav a[href=?]", root_path(day: "Domingo 15"), text: "Domingo 15"
    assert_select "select#commission option[value='Hospitalidad']", text: "Hospitalidad"
    assert_select "thead th", count: 6
    assert_select "thead th:nth-child(1)", text: "Hora Inicio"
    assert_select "thead th:nth-child(2)", text: "Hora Fin"
    assert_select "thead th:nth-child(3)", text: "Duración"
    assert_select "thead th:nth-child(4)", text: "Actividad"
    assert_select "thead th:nth-child(5)", text: "Comisión"
    assert_select "thead th:nth-child(6) .visually-hidden", text: "Preguntas y documentos"

    assert_select "tbody tr", count: 2
    assert_select "tbody tr:first-child" do
      assert_select "td:nth-child(1)", text: "—"
      assert_select "td:nth-child(4)", text: "Recepción de Diócesis"
      assert_select "td:nth-child(5) li", text: "AC"
      assert_select "td:nth-child(5) li", text: "Hospitalidad"
      assert_select "td:nth-child(6) a[href=?]", schedule_entry_path(1), text: "Preguntas y documentos"
    end
  end

  test "shows only activities for the selected day" do
    get root_url(day: "Domingo 15")

    assert_response :success
    assert_select "nav a[aria-current='page']", text: "Domingo 15"
    assert_select "tbody tr:first-child" do
      assert_select "td:nth-child(1)", text: "01:30"
      assert_select "td:nth-child(2)", text: "08:00"
      assert_select "td:nth-child(3)", text: "6:30"
      assert_select "td:nth-child(4)", text: "Instalación de stands"
      assert_select "td:nth-child(5) li", text: "Marketing"
    end
    assert_select "tbody td", text: "Recepción de Diócesis", count: 0
  end

  test "shows Monday activities when its tab is selected" do
    get root_url(day: "Lunes 16")

    assert_response :success
    assert_select "nav a[aria-current='page']", text: "Lunes 16"
    assert_select "tbody tr:first-child td:nth-child(4)", text: "Llegada y música instrumental"
    assert_select "tbody td", text: "Instalación de stands", count: 0
  end

  test "filters activities by commission and preserves the filter across days" do
    get root_url(day: "Domingo 15", commission: "AC")

    assert_response :success
    assert_select "select#commission option[selected][value='AC']"
    assert_select "nav a[href=?]", root_path(day: "Sábado 14", commission: "AC"), text: "Sábado 14"
    assert_select "tbody tr", count: 1
    assert_select "tbody tr td:nth-child(4)", text: "Entrada a la Arena"
    assert_select "tbody tr td:nth-child(5) a[href=?]", root_path(day: "Domingo 15", commission: "Desfile"), text: "Desfile"

    get root_url(day: "Sábado 14", commission: "Marketing")

    assert_response :success
    assert_select "tbody tr td[colspan='6']", text: /No hay actividades de esta comisión/
    assert_select "tbody tr td:nth-child(4)", count: 0
  end
end

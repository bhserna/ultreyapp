require "test_helper"

class ScheduleControllerTest < ActionDispatch::IntegrationTest
  test "shows the schedule on the home page" do
    get root_url

    assert_response :success
    assert_select "h1", text: "Programa"
    assert_select "thead th", count: 5
    assert_select "thead th:nth-child(1)", text: "Día"
    assert_select "thead th:nth-child(2)", text: "Hora Inicio"
    assert_select "thead th:nth-child(3)", text: "Hora Fin"
    assert_select "thead th:nth-child(4)", text: "Duración"
    assert_select "thead th:nth-child(5)", text: "Actividad"

    assert_select "tbody tr:first-child" do
      assert_select "td:nth-child(1)", text: "Sábado 14"
      assert_select "td:nth-child(2)", text: "—"
      assert_select "td:nth-child(5)", text: "Recepción de Diócesis"
    end

    assert_select "tbody tr:nth-child(3)" do
      assert_select "td:nth-child(2)", text: "01:30"
      assert_select "td:nth-child(3)", text: "08:00"
      assert_select "td:nth-child(4)", text: "6:30"
      assert_select "td:nth-child(5)", text: "Instalación de stands"
    end
  end
end

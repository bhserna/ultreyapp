require "test_helper"
require_relative "../support/response_html_assertions"

class OperationalActivitiesControllerTest < ActionDispatch::IntegrationTest
  include ResponseHtmlAssertions

  test "shows the source details without treating the operation as an act" do
    get operational_activity_url(11)

    assert_response :success
    assert_select "h1", text: "Preparación para la transmisión en vivo"
    assert_select ".page__details dd", text: "Servicios y proveedores"
    assert_select ".page__details dd", text: "07:00"
    within(:operational_details) do
      assert_selector :detail_field, "Preguntas para la Arena", text: "Con qué anticipación puede preparar la infraestructura"
      assert_selector :detail_field, "Ejecuta", text: "Proveedor externo (ANetwork)"
      assert_selector :detail_field, "Dudas generales", text: "Con qué laptop o equipo se realizará la transmisión en vivo?"
      assert_selector :detail_field, "Notas", text: "ANetwork solo proporciona el enlace bidireccional de Internet."
    end
    assert_select "a[href=?]", root_path(day: "Domingo 15", commission: "EyA"), text: "EyA"
    assert_select "turbo-frame#questions", count: 0
    assert_select "turbo-frame#documents", count: 0
  end

  test "preserves undecided operation times and the associated arena questions" do
    get operational_activity_url(7)

    assert_response :success
    assert_selector ".page__details dd", exact_text: "Por definir con la Arena"
    within(:operational_details) do
      assert_selector :detail_field, "Preguntas para la Arena", text: "A qué hora puede ser la prueba de sonido e iluminación?"
    end
    assert_no_selector "main", text: "Se finalizan las actividades previas"
  end

  test "returns not found for an unknown operation" do
    get operational_activity_url(999)
    assert_response :not_found
  end
end

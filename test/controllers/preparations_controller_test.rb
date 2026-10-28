require "test_helper"
require_relative "../support/response_html_assertions"

class PreparationsControllerTest < ActionDispatch::IntegrationTest
  include ResponseHtmlAssertions

  test "shows separate preparation actions and links to each related act" do
    get preparation_url(2)

    assert_response :success
    assert_selector "h1", exact_text: "Preparación para el Acto 1 y 2"
    assert_selector "section.page__section", count: 2
    within("section.page__section:nth-of-type(1)", text: "Tener disponibles 10 sillas") do
      assert_selector ".page__details dd", exact_text: "09:45"
      assert_selector "p", text: "Tomar mobiliario de área de resguardo"
      assert_selector :detail_field, "Preguntas para la Arena", text: "Quién proporciona las sillas?"
      assert_selector :detail_field, "Notas", exact_text: "Tener disponibles 10 sillas"
      assert_no_selector "p", text: "Pista Popurri"
    end
    within("section.page__section:nth-of-type(2)", text: "Pista Popurri") do
      assert_selector :detail_field, "Pantalla", exact_text: "Utilizacion de Pantalla completa"
      assert_no_selector "p", text: "Tener disponibles 10 sillas"
    end
    assert_no_selector "section.page__section h2"
    assert_no_selector "main", text: "Acción 1"
    assert_no_selector "main", text: "Acción 2"
    assert_no_selector "main", text: "Colocar el ambón"
    assert_no_selector "main", text: "Escoltar al grupo folclórico a la salida"
    assert_selector :link, href: schedule_entry_path(1)
    assert_selector :link, href: schedule_entry_path(2)
    assert_selector :link, "← Volver al programa", href: root_path(day: "Domingo 15")
  end

  test "keeps preparation actions off the related act page" do
    get schedule_entry_url(1)

    assert_no_selector "h2", exact_text: "Preparaciones"
    assert_no_selector "main", text: "Acciones de preparación"
    assert_no_selector "p", text: "Tener disponibles 10 sillas"
    assert_selector "h2", exact_text: "Detalles de producción"
  end

  test "shows Monday speaker preparation details and the corrected act link" do
    get preparation_url(24)

    assert_response :success
    assert_selector "h1", text: "Acto 24 / Vivencia 6"
    assert_selector ".page__eyebrow", exact_text: "Lunes 16"
    assert_selector ".page__header .page__details dd", exact_text: "11:05"
    assert_selector "section.page__section p", text: "Tener listo al expositor (Pbro. Fernando Torres)"
    assert_selector "section.page__section p", text: "Néstor Velasquez"
    assert_selector :link, href: schedule_entry_path(27)
    assert_no_selector :link, href: schedule_entry_path(26)
    assert_selector :link, "← Volver al programa", href: root_path(day: "Lunes 16")
  end

  test "shows Monday mass preparation details and its related act" do
    get preparation_url(26)

    assert_response :success
    assert_selector ".page__header .page__details dd", exact_text: "12:40"
    assert_selector "section.page__section p", text: "Liturgia prepara lo relacionado a Sacristía"
    assert_selector "section.page__section p", text: "Las pantallas comienzan a mostrar de manera discreta la hora de la Eucaristía"
    assert_selector :link, href: schedule_entry_path(29)
    assert_no_selector "main", text: "Acción 1"
  end

  test "shows an independent preparation without related acts" do
    get preparation_url(1)

    assert_response :success
    assert_selector "h1", exact_text: "Actividades en la Arena previo a que llegue el desfile"
    assert_selector "section.page__section p", text: "Música Ambiental"
    assert_no_selector "h2", exact_text: "Actos relacionados"
    assert_selector :link, "← Volver al programa", href: root_path(day: "Domingo 15")
  end

  test "shows speaker readiness instructions with the corrected act link" do
    get preparation_url(13)

    assert_response :success
    assert_selector "h1", text: "Preparación para el Acto 13"
    assert_selector "section.page__section p", text: "Mantener prevenido a José Humberto Marroquín"
    assert_selector :link, href: schedule_entry_path(16)
  end

  test "shows the next-day preparation on Sunday with its related Monday act" do
    get preparation_url(17)

    assert_response :success
    assert_selector "section.page__section p", text: "Ubicar a la Virgen al centro del escenario"
    assert_selector ".page__eyebrow", exact_text: "Domingo 15"
    assert_selector ".page__header .page__details dd", exact_text: "19:00"
    assert_selector :link, href: schedule_entry_path(20)
  end

  test "rejects missing preparations" do
    get preparation_url(999)

    assert_response :not_found
  end
end

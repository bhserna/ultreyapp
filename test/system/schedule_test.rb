require "application_system_test_case"

class ScheduleTest < ApplicationSystemTestCase
  test "interleaves preparations and acts in the table by start time" do
    visit root_path(day: "Domingo 15")

    assert_selector "tbody tr.schedule__act", count: 19
    assert_selector "tbody tr.schedule__preparation", count: 17
    assert_selector "tr[data-preparation-id='2']", count: 1
    times = all("tbody tr td:nth-child(2)").map(&:text)
    assert_equal times.sort, times
    within("tr[data-preparation-id='2']") do
      assert_selector "td:nth-child(1)", text: "Preparación"
      assert_selector "td:nth-child(2)", text: "09:45"
      assert_text "Preparación para el Acto 1 y 2"
      assert_link "Ver detalle", href: preparation_path(2)
    end
    within("tr[data-preparation-id='7']") do
      assert_selector "td:nth-child(2)", text: "12:30"
      assert_no_text "00:15"
    end
    within("tr[data-preparation-id='12']") do
      assert_selector "td:nth-child(2)", text: "16:50"
    end
    assert_equal "rgb(225, 239, 250)", evaluate_script("getComputedStyle(document.querySelector('tr.schedule__preparation')).backgroundColor")

    click_link "Lunes 16"
    assert_selector "tbody tr.schedule__preparation", count: 9
    assert_selector "tbody tr.schedule__act", count: 12
    within("tr[data-preparation-id='18']") do
      assert_selector "td:nth-child(2)", text: "07:40"
      assert_link "Ver detalle", href: preparation_path(18)
    end
  end

  test "shares the page layout while preserving schedule and activity styles" do
    visit root_path

    assert_selector "main.page.page--wide"
    assert_selector ".page__header.page__header--flush"
    assert_no_selector ".page__eyebrow"
    assert_equal ["1200px", "0px", "32px"], page_layout_styles

    within("tr", text: "Proyección Video Inicio") do
      click_link "Ver detalle"
    end

    assert_selector "main.page:not(.page--wide)"
    assert_selector ".page__eyebrow", text: "DOMINGO 15"
    assert_equal ["800px", "32px", "32px"], page_layout_styles
  end

  test "shows act commissions and excludes preparation and extra activities" do
    visit root_path

    within("tr", text: "Proyección Video Inicio") do
      assert_selector "td:nth-child(6) .commission-links", text: "Programa"
    end
    assert_no_text "Recepción de Diócesis"
    assert_no_text "Instalación de stands"
    assert_no_text "Preparar a los Maestros de ceremonia"
    assert_no_text "Escoltar al grupo folclórico a la salida"

    click_link "Lunes 16"

    within("tr", text: "Desmontaje") do
      assert_link "Todas las comisiones", href: root_path(day: "Lunes 16", commission: "Todas las comisiones")
    end
  end

  test "shows the official schedule times on both days" do
    visit root_path(day: "Domingo 15")

    within("tr", text: "Presentación del Stmo y Entronización de la Virgen.") do
      assert_selector "td:nth-child(1)", text: "4"
      assert_selector "td:nth-child(2)", text: "10:50"
      assert_selector "td:nth-child(3)", text: "11:50"
    end

    click_link "Lunes 16"

    within("tr", text: "Comida") do
      assert_selector "td:nth-child(1)", text: "27"
      assert_selector "td:nth-child(2)", text: "14:25"
      assert_selector "td:nth-child(3)", text: "15:00"
      assert_selector "td:nth-child(6)", text: "Programa"
    end
  end

  test "filters by selecting a commission and keeps it when changing days" do
    visit root_path(day: "Lunes 16")

    select "EyA", from: "Comisión"
    assert_text "No hay actividades de esta comisión para Lunes 16."

    click_link "Domingo 15"
    assert_selector "tbody tr.schedule__act", count: 1
    assert_selector "tbody tr.schedule__preparation", count: 4
    assert_selector "tbody tr td:nth-child(5)", text: "Canto de Colores"
    assert_equal "EyA", find("#commission").value

    select "Sin filtro de comisión", from: "Comisión"
    assert_selector "tbody tr", minimum: 2
  end

  test "distinguishes the all-commissions responsibility from removing the filter" do
    visit root_path(day: "Lunes 16")

    select "Todas las comisiones", from: "Comisión"
    assert_selector "tbody tr.schedule__act", count: 1
    assert_no_selector "tbody tr.schedule__preparation"
    assert_selector "tbody tr td:nth-child(5)", text: "Desmontaje"

    select "Sin filtro de comisión", from: "Comisión"
    assert_selector "tbody tr.schedule__act", count: 12
    assert_selector "tbody tr.schedule__preparation", count: 9
    assert_equal "", find("#commission").value
  end

  test "filters when clicking a commission in the table" do
    visit root_path(day: "Domingo 15")

    within("tr", text: "Canto de Colores") do
      click_link "EyA"
    end

    assert_selector "tbody tr.schedule__act", count: 1
    assert_selector "tbody tr.schedule__preparation", count: 4
    assert_selector "tbody tr td:nth-child(5)", text: "Canto de Colores"
    assert_equal "EyA", find("#commission").value

    click_link "Lunes 16"
    assert_text "No hay actividades de esta comisión para Lunes 16."
  end

  test "places the filter beside day tabs and wraps it on narrow screens" do
    visit root_path

    wide = toolbar_positions
    assert_in_delta wide["daysTop"], wide["filterTop"], 1

    page.driver.browser.manage.window.resize_to(390, 900)
    narrow = toolbar_positions
    assert_operator narrow["filterTop"], :>=, narrow["daysBottom"]
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  test "filters the activity list from a commission link on the detail page" do
    visit root_path

    within("tr", text: "Proyección Video Inicio") do
      click_link "Ver detalle"
    end

    within(".page__header .page__details") do
      assert_selector ".commission-links", text: "Programa"
      assert_link "Programa", href: root_path(day: "Domingo 15", commission: "Programa")
      click_link "Programa"
    end

    assert_selector "nav a[aria-current='page']", text: "Domingo 15"
    assert_equal "Programa", find("#commission").value
    assert_selector "tbody tr.schedule__act", count: 16
    assert_selector "tbody tr.schedule__preparation", count: 2
    assert_selector "tbody tr td:nth-child(5)", text: /Proyección Video Inicio/
  end

  test "keeps access to resources without showing counts beside each activity" do
    Question.create!(schedule_entry_id: 1, body: "Pendiente")
    Question.create!(schedule_entry_id: 1, body: "Contestada", answer: "Listo")
    File.open(Rails.root.join("test/fixtures/files/agenda.txt")) do |file|
      Document.create!(schedule_entry_id: 1, file: { io: file, filename: "agenda.txt", content_type: "text/plain" })
    end

    visit root_path

    assert_no_selector ".schedule__resource-status"
    assert_no_text "Preguntas 2"
    assert_no_text "Contestadas 1"
    assert_no_text "Documentos 1"

    within("tr", text: "Proyección Video Inicio") do
      click_link "Ver detalle"
    end
    assert_text "Pendiente"
    assert_text "Contestada"
    assert_text "agenda.txt"
  end

  private

  def page_layout_styles
    evaluate_script(<<~JAVASCRIPT)
      (() => {
        const container = getComputedStyle(document.querySelector("main.page"))
        const header = getComputedStyle(document.querySelector(".page__header"))
        return [container.maxWidth, header.marginTop, header.marginBottom]
      })()
    JAVASCRIPT
  end

  def toolbar_positions
    evaluate_script(<<~JAVASCRIPT)
      (() => {
        const days = document.querySelector(".tabs").getBoundingClientRect()
        const filter = document.querySelector(".filter").getBoundingClientRect()
        return { daysTop: days.top, daysBottom: days.bottom, filterTop: filter.top }
      })()
    JAVASCRIPT
  end
end

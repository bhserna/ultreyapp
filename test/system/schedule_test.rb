require "application_system_test_case"

class ScheduleTest < ApplicationSystemTestCase
  test "distinguishes preparations with a blue row background" do
    visit root_path(day: "Domingo 15")

    assert_selector :schedule_preparation, 2
    assert_equal "rgb(225, 239, 250)", evaluate_script("getComputedStyle(document.querySelector('tr.schedule__preparation')).backgroundColor")
  end

  test "shares the page layout while preserving schedule and activity styles" do
    visit root_path

    assert_selector "main.page.page--wide"
    assert_selector ".page__header.page__header--flush"
    assert_no_selector ".page__eyebrow"
    assert_equal [ "1200px", "0px", "32px" ], page_layout_styles

    within(:schedule_act, "Proyección Video Inicio") do
      click_link "Ver detalle"
    end

    assert_selector "main.page:not(.page--wide)"
    assert_selector ".page__eyebrow", text: "DOMINGO 15"
    assert_equal [ "800px", "32px", "32px" ], page_layout_styles
  end

  test "shows operations separately and keeps preparation actions off the table" do
    visit root_path

    within(:schedule_act, "Proyección Video Inicio") do
      within(:schedule_cell, :commission) do
        assert_selector ".commission-links", text: "Programa"
      end
    end
    assert_no_text "Recepción de Diócesis"
    within(:schedule_operation, "Instalación de stands") do
      assert_selector :schedule_cell, :act_number, text: "Operación"
      assert_selector ".schedule__category", text: "Montaje e instalaciones"
    end
    assert_no_text "Se finalizan las actividades previas"
    assert_no_text "Preparar a los Maestros de ceremonia"
    assert_no_text "Escoltar al grupo folclórico a la salida"

    click_link "Lunes 16"

    within(:schedule_act, "Desmontaje") do
      assert_link "Todas las comisiones", href: root_path(day: "Lunes 16", commission: "Todas las comisiones")
    end
  end

  test "filters by selecting a commission and keeps it when changing days" do
    visit root_path(day: "Lunes 16")

    select "EyA", from: "Comisión"
    assert_text "No hay actividades de esta comisión para Lunes 16."

    click_link "Domingo 15"
    assert_selector :schedule_act, "Canto de Colores"
    assert_no_selector :schedule_act, "Proyección Video Inicio"
    assert_select "Comisión", selected: "EyA"

    select "Sin filtro de comisión", from: "Comisión"
    assert_selector :schedule_act, "Proyección Video Inicio"
  end

  test "distinguishes the all-commissions responsibility from removing the filter" do
    visit root_path(day: "Lunes 16")

    select "Todas las comisiones", from: "Comisión"
    assert_selector :schedule_act, count: 1
    assert_no_selector :schedule_preparation
    assert_selector :schedule_cell, :activity, text: "Desmontaje"

    select "Sin filtro de comisión", from: "Comisión"
    assert_selector :schedule_preparation, 18
    assert_selector :schedule_act, "Comida"
    assert_select "Comisión", selected: "Sin filtro de comisión"
  end

  test "filters when clicking a commission in the table" do
    visit root_path(day: "Domingo 15")

    within(:schedule_act, "Canto de Colores") do
      click_link "EyA"
    end

    assert_selector :schedule_act, "Canto de Colores"
    assert_no_selector :schedule_act, "Proyección Video Inicio"
    assert_select "Comisión", selected: "EyA"

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
    assert evaluate_script("Array.from(document.querySelectorAll('.filter select')).every(select => select.getBoundingClientRect().right <= window.innerWidth)")
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  test "filters the activity list from a commission link on the detail page" do
    visit root_path

    within(:schedule_act, "Proyección Video Inicio") do
      click_link "Ver detalle"
    end

    within(".page__header .page__details") do
      assert_selector ".commission-links", text: "Programa"
      assert_link "Programa", href: root_path(day: "Domingo 15", commission: "Programa")
      click_link "Programa"
    end

    assert_selector "nav a[aria-current='page']", text: "Domingo 15"
    assert_select "Comisión", selected: "Programa"
    assert_selector :schedule_act, "Proyección Video Inicio"
    assert_no_selector :schedule_act, "Canto de Colores"
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

    within(:schedule_act, "Proyección Video Inicio") do
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

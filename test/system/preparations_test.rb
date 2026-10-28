require "application_system_test_case"

class PreparationsTest < ApplicationSystemTestCase
  test "styles related act links as full-width cards that wrap on narrow screens" do
    visit preparation_path(2)

    within(".related-links") do
      assert_selector "li", count: 2
      assert_selector ".related-links__label", text: "Acto 1"
      assert_selector ".related-links__title", text: "Proyección Video Inicio"
    end
    assert_equal [ "grid", "none", "10.4px" ], evaluate_script(<<~JAVASCRIPT)
      (() => {
        const style = getComputedStyle(document.querySelector('.related-links a'))
        return [style.display, style.textDecorationLine, style.borderTopLeftRadius]
      })()
    JAVASCRIPT

    page.driver.browser.manage.window.resize_to(390, 900)
    assert evaluate_script(<<~JAVASCRIPT)
      (() => {
        const link = document.querySelector('.related-links a').getBoundingClientRect()
        const title = document.querySelector('.related-links__title').getBoundingClientRect()
        return link.right <= window.innerWidth && title.right <= link.right && title.height > 30
      })()
    JAVASCRIPT
    within(".related-links") { find("a[href='#{schedule_entry_path(1)}']").click }
    assert_current_path schedule_entry_path(1)
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  test "opens preparation details from the program and keeps actions off the act page" do
    visit root_path(day: "Domingo 15")
    within(:schedule_preparation, 2) { click_link "Ver detalle" }

    assert_current_path preparation_path(2)
    assert_selector "h1", text: "Preparación para el Acto 1 y 2"
    assert_text "09:45"
    assert_text "Tomar mobiliario de área de resguardo"
    assert_text "Tener disponibles 10 sillas"
    assert_text "Quién proporciona las sillas?"
    assert_text "Utilizacion de Pantalla completa"
    assert_text "Pista Popurri"
    assert_selector "section.page__section", count: 2
    assert_no_text "Acción 1"
    assert_no_text "Acción 2"
    within("section.page__section", text: "Tener disponibles 10 sillas") do
      assert_text "09:45"
      assert_text "Tener disponibles 10 sillas"
      assert_no_text "Pista Popurri"
    end
    within("section.page__section", text: "Pista Popurri") do
      assert_text "Pista Popurri"
      assert_no_text "Tener disponibles 10 sillas"
    end
    assert_no_text "Colocar el ambón"
    assert_no_text "Escoltar al grupo folclórico a la salida"
    assert_link href: schedule_entry_path(1)
    assert_link href: schedule_entry_path(2)

    click_link "← Volver al programa"
    assert_current_path root_path(day: "Domingo 15")
    within(:schedule_act, "Proyección Video Inicio") { click_link "Ver detalle" }
    assert_current_path schedule_entry_path(1)
    assert_no_text "Acciones de preparación"
    assert_no_text "Tener disponibles 10 sillas"
    assert_text "Detalles de producción"
  end

  test "opens Monday preparations with their action details and corrected act links" do
    visit root_path(day: "Lunes 16")
    within(:schedule_preparation, 24) { click_link "Ver detalle" }

    assert_current_path preparation_path(24)
    assert_selector "h1", text: "Acto 24 / Vivencia 6"
    assert_selector ".page__eyebrow", text: "LUNES 16"
    assert_text "11:05"
    assert_text "Tener listo al expositor (Pbro. Fernando Torres)"
    assert_text "Néstor Velasquez"
    assert_link href: schedule_entry_path(27)
    assert_no_link href: schedule_entry_path(26)

    click_link "← Volver al programa"
    assert_current_path root_path(day: "Lunes 16")
    within(:schedule_preparation, 26) { click_link "Ver detalle" }

    assert_text "12:40"
    assert_text "Liturgia prepara lo relacionado a Sacristía"
    assert_text "Las pantallas comienzan a mostrar de manera discreta la hora de la Eucaristía"
    assert_link href: schedule_entry_path(29)
    assert_no_text "Acción 1"
  end

  test "shows independent preparations and links corrected act references" do
    visit preparation_path(1)
    assert_selector "h1", text: "Actividades en la Arena previo a que llegue el desfile"
    assert_text "Música Ambiental"
    assert_no_text "Actos relacionados"
    assert_link "← Volver al programa", href: root_path(day: "Domingo 15")

    visit preparation_path(13)
    assert_selector "h1", text: "Preparación para el Acto 13"
    assert_text "Mantener prevenido a José Humberto Marroquín"
    assert_link href: schedule_entry_path(16)

    visit preparation_path(17)
    assert_text "Ubicar a la Virgen al centro del escenario"
    assert_selector ".page__eyebrow", text: "DOMINGO 15"
    assert_text "19:00"
    assert_link href: schedule_entry_path(20)
  end
end

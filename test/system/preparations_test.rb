require "application_system_test_case"

class PreparationsTest < ApplicationSystemTestCase
  test "styles related act links as full-width cards that wrap on narrow screens" do
    visit preparation_path(2)

    assert_selector :related_act, count: 2
    assert_selector :related_act, "Acto 1", text: "Proyección Video Inicio"
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
    find(:related_act, "Acto 1").click
    assert_current_path schedule_entry_path(1)
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end

  test "navigates from the program to a preparation and its related act and back" do
    visit root_path(day: "Domingo 15")
    within(:schedule_preparation, 2) { click_link "Ver detalle" }

    assert_current_path preparation_path(2)
    assert_selector "h1", text: "Preparación para el Acto 1 y 2"
    assert_text "Tener disponibles 10 sillas"

    find(:related_act, "Acto 1").click
    assert_current_path schedule_entry_path(1)
    assert_selector "h1", text: "Proyección Video Inicio"

    click_link "← Volver al programa"
    assert_current_path root_path(day: "Domingo 15")
  end
end

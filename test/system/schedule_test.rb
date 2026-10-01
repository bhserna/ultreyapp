require "application_system_test_case"

class ScheduleTest < ApplicationSystemTestCase
  test "shows each activity commission separately" do
    visit root_path

    within("tr", text: "Recepción de Diócesis") do
      assert_selector "td:nth-child(5) .commission-links", text: "AC, Hospitalidad"
    end

    click_link "Domingo 15"

    within("tr", text: "Entrada a la Arena") do
      assert_selector "td:nth-child(5) .commission-links", text: "Desfile, AC"
    end

    click_link "Lunes 16"

    within("tr", text: "Desmontaje") do
      assert_selector "td:nth-child(5)", text: "—"
      assert_no_selector "td:nth-child(5) .commission-links"
    end
  end

  test "filters by selecting a commission and keeps it when changing days" do
    visit root_path

    select "Marketing", from: "Comisión"
    assert_text "No hay actividades de esta comisión para Sábado 14."

    click_link "Domingo 15"
    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr td:nth-child(4)", text: "Instalación de stands"
    assert_equal "Marketing", find("#commission").value

    select "Todas las comisiones", from: "Comisión"
    assert_selector "tbody tr", minimum: 2
  end

  test "filters when clicking a commission in the table" do
    visit root_path(day: "Domingo 15")

    within("tr", text: "Entrada a la Arena") do
      click_link "AC"
    end

    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr td:nth-child(4)", text: "Entrada a la Arena"
    assert_equal "AC", find("#commission").value

    click_link "Sábado 14"
    assert_selector "tbody tr", count: 2
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

    within("tr", text: "Recepción de Diócesis") do
      click_link "Preguntas y documentos"
    end

    within(".activity-page__details") do
      assert_selector ".commission-links", text: "AC, Hospitalidad"
      assert_link "AC", href: root_path(day: "Sábado 14", commission: "AC")
      click_link "Hospitalidad"
    end

    assert_selector "nav a[aria-current='page']", text: "Sábado 14"
    assert_equal "Hospitalidad", find("#commission").value
    assert_selector "tbody tr", count: 1
    assert_selector "tbody tr td:nth-child(4)", text: "Recepción de Diócesis"
  end

  private

  def toolbar_positions
    evaluate_script(<<~JAVASCRIPT)
      (() => {
        const days = document.querySelector(".schedule__days").getBoundingClientRect()
        const filter = document.querySelector(".schedule__filter").getBoundingClientRect()
        return { daysTop: days.top, daysBottom: days.bottom, filterTop: filter.top }
      })()
    JAVASCRIPT
  end
end

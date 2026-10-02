require "application_system_test_case"

class GeneralQuestionsTest < ApplicationSystemTestCase
  test "navigates between the schedule and general questions and manages a question" do
    visit root_path

    within(".site-nav") do
      assert_link "Programa", href: root_path
      click_link "Preguntas generales"
    end

    assert_selector "h1", text: "Preguntas generales"
    assert_selector ".site-nav a[aria-current='page']", text: "Preguntas generales"
    assert_text "Todavía no hay preguntas generales."

    click_button "Nueva pregunta"
    fill_in "Nueva pregunta", with: "¿Dónde nos reunimos?"
    click_button "Guardar pregunta"

    within(".questions__item", text: "¿Dónde nos reunimos?") do
      click_link "Editar"
    end
    fill_in "Pregunta", with: "¿A qué hora nos reunimos?"
    click_button "Guardar cambios"

    within(".questions__item", text: "¿A qué hora nos reunimos?") do
      click_link "Responder"
    end
    fill_in "Respuesta", with: "A las nueve."
    click_button "Guardar respuesta"

    within(".questions__item", text: "¿A qué hora nos reunimos?") do
      assert_text "A las nueve."
      click_link "Editar respuesta"
    end
    fill_in "Respuesta", with: "A las diez."
    click_button "Guardar respuesta"

    within(".questions__item", text: "¿A qué hora nos reunimos?") do
      assert_text "A las diez."
      accept_confirm { click_button "Eliminar" }
    end
    assert_text "Todavía no hay preguntas generales."

    within(".site-nav") { click_link "Programa" }
    assert_selector "h1", text: "Programa"
    assert_selector ".site-nav a[aria-current='page']", text: "Programa"
  end
end

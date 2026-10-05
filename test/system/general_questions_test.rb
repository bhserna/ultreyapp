require "application_system_test_case"

class GeneralQuestionsTest < ApplicationSystemTestCase
  test "navigates between the schedule and general questions and manages a question" do
    visit root_path

    within(".site-nav") do
      assert_link "Programa", href: root_path
      click_link "Preguntas generales"
    end

    assert_selector "h1", text: "Preguntas generales"
    assert_selector "main.activity-page--wide"
    assert_selector ".site-nav a[aria-current='page']", text: "Preguntas generales"
    assert_text "Todavía no hay preguntas generales sin tema."

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
    assert_text "Todavía no hay preguntas generales sin tema."

    within(".site-nav") { click_link "Programa" }
    assert_selector "h1", text: "Programa"
    assert_selector ".site-nav a[aria-current='page']", text: "Programa"
  end

  test "manages topics and scopes general questions to the selected topic" do
    visit questions_path

    within(".topics") do
      assert_link "Sin tema"
      assert_link "Editar", href: topics_path
      assert_no_button "Nuevo tema"
      click_link "Editar"
    end

    assert_current_path topics_path
    assert_selector "main.activity-page:not(.activity-page--wide)"
    assert_text "Todavía no hay temas."
    click_button "Nuevo tema"
    assert_selector "input[name='topic[name]'][required]"
    fill_in "Nombre", with: "Logística"
    click_button "Guardar tema"
    assert_current_path topics_path
    assert_selector ".topics__management-item", text: "Logística"

    click_link "← Volver a las preguntas generales"

    within(".topics") { click_link "Logística" }
    assert_text "Todavía no hay preguntas para este tema."
    click_button "Nueva pregunta"
    fill_in "Nueva pregunta", with: "¿Dónde está el material?"
    click_button "Guardar pregunta"
    assert_selector ".questions__item", text: "¿Dónde está el material?"
    assert_equal "Logística", Question.find_by!(body: "¿Dónde está el material?").topic.name

    within(".topics") { click_link "Sin tema" }
    assert_no_selector ".questions__item", text: "¿Dónde está el material?"
    click_button "Nueva pregunta"
    fill_in "Nueva pregunta", with: "¿Cuándo empieza?"
    click_button "Guardar pregunta"
    assert_selector ".questions__item", text: "¿Cuándo empieza?"

    within(".topics") { click_link "Logística" }
    assert_no_selector ".questions__item", text: "¿Cuándo empieza?"
    within(".questions__item", text: "¿Dónde está el material?") { click_link "Editar" }
    fill_in "Pregunta", with: "¿Dónde guardamos el material?"
    click_button "Guardar cambios"
    assert_selector ".questions__item", text: "¿Dónde guardamos el material?"

    within(".questions__item", text: "¿Dónde guardamos el material?") { click_link "Responder" }
    fill_in "Respuesta", with: "En la bodega."
    click_button "Guardar respuesta"
    assert_selector ".topics__tab[aria-current='page']", text: "Logística"
    within(".questions__item", text: "¿Dónde guardamos el material?") { assert_text "En la bodega." }

    within(".topics") do
      assert_no_selector "button"
      click_link "Editar"
    end
    within(".topics__management-item", text: "Logística") { find("a[aria-label='Editar tema Logística']").click }
    assert_current_path topics_path
    assert_selector "h1", text: "Editar temas"
    within("turbo-frame#topic_#{Topic.find_by!(name: "Logística").id}") do
      assert_field "Nombre", with: "Logística"
      click_link "Cancelar"
    end
    assert_selector ".topics__management-item", text: "Logística"

    within(".topics__management-item", text: "Logística") { find("a[aria-label='Editar tema Logística']").click }
    within("turbo-frame#topic_#{Topic.find_by!(name: "Logística").id}") do
      fill_in "Nombre", with: "Materiales"
      click_button "Guardar cambios"
    end
    assert_current_path topics_path
    assert_selector ".topics__management-item", text: "Materiales"

    click_link "← Volver a las preguntas generales"
    within(".topics") { click_link "Materiales" }
    assert_selector ".topics__tab[aria-current='page']", text: "Materiales"
    assert_selector ".questions__item", text: "¿Dónde guardamos el material?"

    within(".topics") { click_link "Editar" }
    within(".topics__management-item", text: "Materiales") do
      accept_confirm { find("button[aria-label='Eliminar tema Materiales']").click }
    end
    assert_current_path topics_path
    click_link "← Volver a las preguntas generales"
    assert_selector ".topics__tab[aria-current='page']", text: "Sin tema"
    assert_selector ".questions__item", text: "¿Dónde guardamos el material?"
    assert_nil Question.find_by!(body: "¿Dónde guardamos el material?").topic
  end
end

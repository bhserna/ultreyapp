require "application_system_test_case"

class GeneralQuestionsTest < ApplicationSystemTestCase
  test "navigates between the schedule and general questions" do
    visit root_path

    within(".site-nav") do
      assert_link "Programa", href: root_path
      click_link "Preguntas generales"
    end

    assert_selector "h1", text: "Preguntas generales"
    assert_selector "main.page.page--wide"
    assert_selector ".site-nav a[aria-current='page']", text: "Preguntas generales"
    assert_text "Todavía no hay preguntas generales sin tema."

    within(".site-nav") { click_link "Programa" }
    assert_selector "h1", text: "Programa"
    assert_selector ".site-nav a[aria-current='page']", text: "Programa"
  end

  test "creates a general question without a topic" do
    visit questions_path

    click_button "Nueva pregunta"
    fill_in "Nueva pregunta", with: "¿Dónde nos reunimos?"
    click_button "Guardar pregunta"

    assert_selector :selected_topic, "Sin tema"
    assert_selector :question, "¿Dónde nos reunimos?"
  end

  test "edits a general question" do
    question = Question.create!(body: "¿Dónde nos reunimos?")
    visit questions_path

    within(:question, question.body) { click_link "Editar" }
    fill_in "Pregunta", with: "¿A qué hora nos reunimos?"
    click_button "Guardar cambios"

    assert_selector :question, "¿A qué hora nos reunimos?"
    assert_no_selector :question, question.body
  end

  test "answers a general question" do
    question = Question.create!(body: "¿A qué hora nos reunimos?")
    visit questions_path

    within(:question, question.body) { click_link "Responder" }
    fill_in "Respuesta", with: "A las nueve."
    click_button "Guardar respuesta"

    within(:question, question.body) do
      assert_text "A las nueve."
      assert_link "Editar respuesta"
    end
  end

  test "updates an existing answer" do
    question = Question.create!(body: "¿A qué hora nos reunimos?", answer: "A las nueve.")
    visit questions_path

    within(:question, question.body) { click_link "Editar respuesta" }
    fill_in "Respuesta", with: "A las diez."
    click_button "Guardar respuesta"

    within(:question, question.body) do
      assert_text "A las diez."
      assert_no_text "A las nueve."
    end
  end

  test "deletes a general question after confirmation" do
    question = Question.create!(body: "¿Dónde nos reunimos?")
    visit questions_path

    within(:question, question.body) do
      accept_confirm { click_button "Eliminar" }
    end

    assert_no_selector :question, question.body
    assert_text "Todavía no hay preguntas generales sin tema."
  end

  test "creates a topic from topic management" do
    visit questions_path

    within(".topics") do
      assert_link "Sin tema"
      assert_link "Editar", href: topics_path
      assert_no_button "Nuevo tema"
      click_link "Editar"
    end

    assert_current_path topics_path
    assert_selector "main.page:not(.page--wide)"
    assert_text "Todavía no hay temas."
    click_button "Nuevo tema"
    assert_field("Nombre") { |field| field[:required] }
    fill_in "Nombre", with: "Logística"
    click_button "Guardar tema"

    assert_current_path topics_path
    assert_selector :topic_item, "Logística"
    click_link "← Volver a las preguntas generales"
    within(".topics") { click_link "Logística" }
    assert_selector :selected_topic, "Logística"
    assert_text "Todavía no hay preguntas para este tema."
  end

  test "shows only questions from the selected topic" do
    topic = Topic.create!(name: "Logística")
    other_topic = Topic.create!(name: "Comunicación")
    question = Question.create!(body: "¿Dónde está el material?", topic: topic)
    other_question = Question.create!(body: "¿Quién hace el anuncio?", topic: other_topic)
    unassigned_question = Question.create!(body: "¿Cuándo empieza?")
    visit questions_path

    assert_selector :question, unassigned_question.body
    assert_no_selector :question, question.body
    assert_no_selector :question, other_question.body

    within(".topics") { click_link "Logística" }
    assert_selector :selected_topic, "Logística"
    assert_selector :question, question.body
    assert_no_selector :question, unassigned_question.body
    assert_no_selector :question, other_question.body

    within(".topics") { click_link "Sin tema" }
    assert_selector :selected_topic, "Sin tema"
    assert_selector :question, unassigned_question.body
    assert_no_selector :question, question.body
  end

  test "creates a question in the selected topic" do
    topic = Topic.create!(name: "Logística")
    visit questions_path(topic_id: topic.id)

    click_button "Nueva pregunta"
    fill_in "Nueva pregunta", with: "¿Dónde está el material?"
    click_button "Guardar pregunta"

    assert_selector :selected_topic, "Logística"
    assert_selector :question, "¿Dónde está el material?"
    within(".topics") { click_link "Sin tema" }
    assert_no_selector :question, "¿Dónde está el material?"
  end

  test "keeps the selected topic after editing and answering a question" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "¿Dónde está el material?", topic: topic)
    visit questions_path(topic_id: topic.id)

    within(:question, question.body) { click_link "Editar" }
    fill_in "Pregunta", with: "¿Dónde guardamos el material?"
    click_button "Guardar cambios"

    assert_selector :selected_topic, "Logística"
    within(:question, "¿Dónde guardamos el material?") { click_link "Responder" }
    fill_in "Respuesta", with: "En la bodega."
    click_button "Guardar respuesta"

    assert_selector :selected_topic, "Logística"
    within(:question, "¿Dónde guardamos el material?") { assert_text "En la bodega." }
  end

  test "cancels editing a topic without changing its name" do
    Topic.create!(name: "Logística")
    visit topics_path

    within(:topic_item, "Logística") do
      click_link "Editar tema Logística"
      assert_field "Nombre", with: "Logística"
      fill_in "Nombre", with: "Materiales"
      click_link "Cancelar"
    end

    assert_current_path topics_path
    assert_selector "h1", text: "Editar temas"
    assert_selector :topic_item, "Logística"
    assert_no_selector :topic_item, "Materiales"
  end

  test "renames a topic without losing its questions" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "¿Dónde guardamos el material?", topic: topic)
    visit topics_path

    within(:topic_item, "Logística") do
      click_link "Editar tema Logística"
      fill_in "Nombre", with: "Materiales"
      click_button "Guardar cambios"
    end

    assert_selector :topic_item, "Materiales"
    assert_no_selector :topic_item, "Logística"
    click_link "← Volver a las preguntas generales"
    within(".topics") { click_link "Materiales" }
    assert_selector :selected_topic, "Materiales"
    assert_selector :question, question.body
  end

  test "moves questions to no topic when their topic is deleted" do
    topic = Topic.create!(name: "Materiales")
    question = Question.create!(body: "¿Dónde guardamos el material?", topic: topic)
    visit topics_path

    within(:topic_item, "Materiales") do
      accept_confirm { click_button "Eliminar tema Materiales" }
    end

    assert_current_path topics_path
    assert_no_selector :topic_item, "Materiales"
    click_link "← Volver a las preguntas generales"
    assert_selector :selected_topic, "Sin tema"
    assert_selector :question, question.body
    within(".topics") { assert_no_link "Materiales" }
  end

  test "clears a blank answer on a general question" do
    question = Question.create!(body: "¿Dónde nos reunimos?", answer: "En la sala principal.")
    visit questions_path

    within(:question, question.body) { click_link "Editar respuesta" }
    fill_in "Respuesta", with: "  \n  "
    click_button "Guardar respuesta"

    assert_current_path questions_path
    within(:question, question.body) do
      assert_link "Responder"
      assert_no_selector ".questions__answer"
    end
    assert_nil question.reload.answer
  end
end

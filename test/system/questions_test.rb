require "application_system_test_case"

class QuestionsTest < ApplicationSystemTestCase
  test "show general questions" do
    question = Question.create!(body: "¿Cuándo empieza?")
    topic = Topic.create!(name: "Logística")
    topic_question = Question.create!(body: "¿Dónde está el material?", topic: topic)
    act_question = Question.create!(body: "¿Quién presenta?", act_id: activities(:opening_act).id)
    visit root_path

    within(".site-nav") { click_link "Preguntas generales" }

    assert_selector :question, question.body
    assert_no_selector :question, topic_question.body
    assert_no_selector :question, act_question.body
  end

  test "filter by topic" do
    topic = Topic.create!(name: "Logística")
    other_topic = Topic.create!(name: "Comunicación")
    question = Question.create!(body: "¿Dónde está el material?", topic: topic)
    other_question = Question.create!(body: "¿Quién hace el anuncio?", topic: other_topic)
    unassigned_question = Question.create!(body: "¿Cuándo empieza?")
    visit questions_path

    within(".topics") { click_link topic.name }

    assert_selector :selected_topic, topic.name
    assert_selector :question, question.body
    assert_no_selector :question, unassigned_question.body
    assert_no_selector :question, other_question.body

    within(".topics") { click_link "Sin tema" }
    assert_selector :question, unassigned_question.body
    assert_no_selector :question, question.body
  end

  test "create a question without a topic" do
    visit questions_path

    click_button "Nueva pregunta"
    fill_in "Nueva pregunta", with: "¿Dónde nos reunimos?"
    click_button "Guardar pregunta"

    assert_selector :selected_topic, "Sin tema"
    assert_selector :question, "¿Dónde nos reunimos?"
  end

  test "create a question in a topic" do
    topic = Topic.create!(name: "Logística")
    visit questions_path(topic_id: topic.id)

    click_button "Nueva pregunta"
    fill_in "Nueva pregunta", with: "¿Dónde está el material?"
    click_button "Guardar pregunta"

    assert_selector :selected_topic, topic.name
    assert_selector :question, "¿Dónde está el material?"
    within(".topics") { click_link "Sin tema" }
    assert_no_selector :question, "¿Dónde está el material?"
  end

  test "edit a question" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "¿Dónde nos reunimos?", topic: topic)
    visit questions_path(topic_id: topic.id)

    within(:question, question.body) { click_link "Editar" }
    fill_in "Pregunta", with: "¿A qué hora nos reunimos?"
    click_button "Guardar cambios"

    assert_selector :selected_topic, topic.name
    assert_selector :question, "¿A qué hora nos reunimos?"
    assert_no_selector :question, question.body
  end

  test "delete a question" do
    question = Question.create!(body: "¿Dónde nos reunimos?")
    visit questions_path

    within(:question, question.body) do
      accept_confirm { click_button "Eliminar" }
    end

    assert_no_selector :question, question.body
    assert_text "Todavía no hay preguntas generales sin tema."
  end

  test "answer a question" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "¿A qué hora nos reunimos?", topic: topic)
    visit questions_path(topic_id: topic.id)

    within(:question, question.body) { click_link "Responder" }
    fill_in "Respuesta", with: "A las nueve."
    click_button "Guardar respuesta"

    assert_selector :selected_topic, topic.name
    within(:question, question.body) do
      assert_text "A las nueve."
      assert_link "Editar respuesta"
    end
  end

  test "edit an answer" do
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

  test "clear an answer" do
    question = Question.create!(body: "¿Dónde nos reunimos?", answer: "En la sala principal.")
    visit questions_path

    within(:question, question.body) { click_link "Editar respuesta" }
    fill_in "Respuesta", with: "  \n  "
    click_button "Guardar respuesta"

    within(:question, question.body) do
      assert_link "Responder"
      assert_no_selector ".questions__answer"
    end
  end
end

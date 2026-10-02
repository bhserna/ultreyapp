require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  test "shows activity details and manages its questions" do
    get schedule_entry_url(3)

    assert_response :success
    assert_select "h1", text: "Instalación de stands"
    assert_select ".activity-page__eyebrow", text: "Domingo 15"
    assert_select ".activity-page__details dd", text: "01:30"
    assert_select ".activity-page__details dt", text: "Día", count: 0
    assert_select "turbo-frame#questions[src=?]", schedule_entry_questions_path(3)

    get schedule_entry_questions_url(3)
    assert_response :success
    assert_select "turbo-frame#questions form[action=?]", schedule_entry_questions_path(3)

    assert_difference("Question.count", 1) do
      post schedule_entry_questions_url(3), params: { question: { body: "¿Quién participa?" } }
    end

    question = Question.order(:id).last
    assert_equal 3, question.schedule_entry_id
    assert_redirected_to schedule_entry_questions_url(3)

    get schedule_entry_questions_url(3)
    assert_select ".questions__item", text: /¿Quién participa\?/
    assert_select "turbo-frame#question_#{question.id}"

    get edit_question_url(question)
    assert_response :success
    assert_select "turbo-frame#question_#{question.id}"
    assert_select "textarea", text: "¿Quién participa?"
    assert_select ".site-nav a[aria-current='page']", text: "Programa"

    patch question_url(question), params: { question: { body: "¿Quién coordina?" } }
    assert_redirected_to schedule_entry_questions_url(3)
    assert_equal "¿Quién coordina?", question.reload.body

    assert_difference("Question.count", -1) do
      delete question_url(question)
    end
    assert_redirected_to schedule_entry_questions_url(3)
  end

  test "keeps questions scoped to their activity" do
    question = Question.create!(schedule_entry_id: 3, body: "Pregunta privada de la actividad")
    get schedule_entry_questions_url(4)
    assert_select ".questions__item", count: 0

    get schedule_entry_questions_url(3)
    assert_select ".questions__item a[href=?]", edit_question_path(question), text: "Editar"
    assert_select ".questions__item a[href=?]", edit_question_answer_path(question), text: "Responder"
    assert_select ".questions__item form[action=?]", question_path(question)
  end

  test "keeps general questions separate from activity questions" do
    general_question = Question.create!(body: "Pregunta general")
    activity_question = Question.create!(schedule_entry_id: 3, body: "Pregunta de la actividad")

    get questions_url
    assert_response :success
    assert_select ".questions__item", text: /Pregunta general/, count: 1
    assert_select ".questions__item", text: /Pregunta de la actividad/, count: 0

    get schedule_entry_questions_url(3)
    assert_select ".questions__item", text: /Pregunta general/, count: 0
    assert_select ".questions__item", text: /Pregunta de la actividad/, count: 1

    get edit_question_url(activity_question)
    assert_response :success
    assert_select ".activity-page__eyebrow", text: /Instalación de stands/
    assert_select ".site-nav a[aria-current='page']", text: "Programa"

    get edit_question_url(general_question)
    assert_response :success
    assert_select ".activity-page__eyebrow", count: 0
    assert_select ".site-nav a[aria-current='page']", text: "Preguntas generales"

    patch question_answer_url(activity_question), params: { question: { answer: "Respuesta de la actividad" } }
    assert_redirected_to schedule_entry_questions_url(3)
    patch question_answer_url(general_question), params: { question: { answer: "Respuesta general" } }
    assert_redirected_to questions_url
  end
end

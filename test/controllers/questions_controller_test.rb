require "test_helper"
require_relative "../support/response_html_assertions"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  include ResponseHtmlAssertions

  test "shows activity details and manages its questions" do
    get schedule_entry_url(3)

    assert_response :success
    assert_select "h1", text: "Presentación: saludos y palabras de autoridades"
    assert_select ".page__eyebrow", text: "Domingo 15"
    assert_select ".page__details dd", text: "10:20"
    assert_select ".page__details dt", text: "Día", count: 0
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
    assert_selector :question, "¿Quién participa?"
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
    assert_no_selector :question

    get schedule_entry_questions_url(3)
    within(:question, question.body) do
      assert_selector :link, "Editar", href: edit_question_path(question)
      assert_selector :link, "Responder", href: edit_question_answer_path(question)
      assert_selector "form[action='#{question_path(question)}']"
    end
  end

  test "keeps general questions separate from activity questions" do
    general_question = Question.create!(body: "Pregunta general")
    activity_question = Question.create!(schedule_entry_id: 3, body: "Pregunta de la actividad")

    get questions_url
    assert_response :success
    assert_selector :question, general_question.body, count: 1
    assert_no_selector :question, activity_question.body

    get schedule_entry_questions_url(3)
    assert_no_selector :question, general_question.body
    assert_selector :question, activity_question.body, count: 1

    get edit_question_url(activity_question)
    assert_response :success
    assert_select ".page__eyebrow", text: /Presentación: saludos y palabras de autoridades/
    assert_select ".site-nav a[aria-current='page']", text: "Programa"

    get edit_question_url(general_question)
    assert_response :success
    assert_select ".page__eyebrow", count: 0
    assert_select ".site-nav a[aria-current='page']", text: "Preguntas generales"

    patch question_answer_url(activity_question), params: { question: { answer: "Respuesta de la actividad" } }
    assert_redirected_to schedule_entry_questions_url(3)
    patch question_answer_url(general_question), params: { question: { answer: "Respuesta general" } }
    assert_redirected_to questions_url
  end

  test "filters general questions by the selected topic" do
    topic = Topic.create!(name: "Logística")
    other_topic = Topic.create!(name: "Comunicación")
    unassigned_question = Question.create!(body: "Pregunta sin tema")
    selected_question = Question.create!(body: "Pregunta de logística", topic: topic)
    Question.create!(body: "Pregunta de comunicación", topic: other_topic)
    Question.create!(body: "Pregunta de actividad", schedule_entry_id: 3)

    get questions_url
    assert_response :success
    assert_selector :selected_topic, "Sin tema"
    within(:question, unassigned_question.body) do
      assert_selector "turbo-frame#question_#{unassigned_question.id}"
    end
    assert_selector :question, count: 1

    get questions_url(topic_id: topic.id)
    assert_response :success
    assert_selector :selected_topic, "Logística"
    within(:question, selected_question.body) do
      assert_selector "turbo-frame#question_#{selected_question.id}"
    end
    assert_selector :question, count: 1
    assert_select "form[action=?]", questions_path(topic_id: topic.id)
  end

  test "creates a question in the selected topic" do
    topic = Topic.create!(name: "Logística")
    other_topic = Topic.create!(name: "Comunicación")

    assert_difference("Question.count", 1) do
      post questions_url(topic_id: topic.id), params: { question: { body: "¿Dónde está el material?", topic_id: other_topic.id } }
    end

    question = Question.order(:id).last
    assert_equal topic, question.topic
    assert_nil question.schedule_entry_id
    assert_redirected_to questions_url(topic_id: topic.id)
  end

  test "keeps the topic when editing or deleting a general question" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "Pregunta original", topic: topic)

    get edit_question_url(question)
    assert_response :success
    assert_select "a[href=?]", questions_path(topic_id: topic.id), text: /Volver a las preguntas/

    patch question_url(question), params: { question: { body: "Pregunta actualizada" } }
    assert_equal "Pregunta actualizada", question.reload.body
    assert_redirected_to questions_url(topic_id: topic.id)

    assert_difference("Question.count", -1) { delete question_url(question) }
    assert_redirected_to questions_url(topic_id: topic.id)
  end

  test "ignores topic selection for activity questions" do
    topic = Topic.create!(name: "Logística")

    assert_difference("Question.count", 1) do
      post schedule_entry_questions_url(3, topic_id: topic.id), params: { question: { body: "Pregunta de actividad" } }
    end

    question = Question.order(:id).last
    assert_equal 3, question.schedule_entry_id
    assert_nil question.topic_id
    assert_redirected_to schedule_entry_questions_url(3)
  end
end

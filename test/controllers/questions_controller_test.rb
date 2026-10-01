require "test_helper"

class QuestionsControllerTest < ActionDispatch::IntegrationTest
  test "shows activity details and manages its questions" do
    get schedule_entry_url(3)

    assert_response :success
    assert_select "h1", text: "Instalación de stands"
    assert_select ".activity-page__eyebrow", text: "Domingo 15"
    assert_select ".questions__details dd", text: "01:30"
    assert_select ".questions__details dt", text: "Día", count: 0
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

    get edit_schedule_entry_question_url(3, question)
    assert_response :success
    assert_select "turbo-frame#question_#{question.id}"
    assert_select "textarea", text: "¿Quién participa?"

    patch schedule_entry_question_url(3, question), params: { question: { body: "¿Quién coordina?" } }
    assert_redirected_to schedule_entry_questions_url(3)
    assert_equal "¿Quién coordina?", question.reload.body

    assert_difference("Question.count", -1) do
      delete schedule_entry_question_url(3, question)
    end
    assert_redirected_to schedule_entry_questions_url(3)
  end

  test "keeps questions scoped to their activity" do
    question = Question.create!(schedule_entry_id: 3, body: "Pregunta privada de la actividad")
    get schedule_entry_questions_url(4)
    assert_select ".questions__item", count: 0

    get edit_schedule_entry_question_url(4, question)
    assert_response :not_found
  end
end

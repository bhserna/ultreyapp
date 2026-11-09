require "application_request_test_case"

class AnswersControllerTest < ApplicationRequestTestCase
  test "update only the answer" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "Pregunta original", topic: topic, answer: "Respuesta original")
    original_attributes = question.attributes.except("answer", "updated_at")

    patch question_answer_url(question), params: {
      question: { answer: "Respuesta actualizada", body: "Texto manipulado", act_id: activities(:opening_act).id, topic_id: nil }
    }

    assert_response :see_other
    assert_equal "Respuesta actualizada", question.reload.answer
    assert_equal original_attributes, question.attributes.except("answer", "updated_at")
  end

  test "return to the question context" do
    act = activities(:opening_act)
    topic = Topic.create!(name: "Logística")
    other_topic = Topic.create!(name: "Comunicación")
    contexts = [
      [ Question.create!(body: "Pregunta del acto", act_id: act.id), schedule_entry_questions_url(act) ],
      [ Question.create!(body: "Pregunta del tema", topic: topic), questions_url(topic_id: topic.id) ],
      [ Question.create!(body: "Pregunta sin tema"), questions_url ]
    ]

    contexts.each do |question, destination|
      patch question_answer_url(question, topic_id: other_topic.id, schedule_entry_id: activities(:closing_act).id), params: {
        question: { answer: "Respuesta guardada" }
      }

      assert_response :see_other
      assert_redirected_to destination
      assert_equal "Respuesta guardada", question.reload.answer
    end
  end
end

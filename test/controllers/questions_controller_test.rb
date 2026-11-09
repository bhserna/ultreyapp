require "application_request_test_case"

class QuestionsControllerTest < ApplicationRequestTestCase
  test "create under the act in the URL" do
    act = activities(:opening_act)
    topic = Topic.create!(name: "Logística")

    assert_difference "Question.count", 1 do
      post schedule_entry_questions_url(act), params: {
        question: { body: "¿Quién coordina?", act_id: activities(:closing_act).id, topic_id: topic.id }
      }
    end

    question = Question.order(:id).last
    assert_equal act.id, question.act_id
    assert_nil question.topic_id
    assert_redirected_to schedule_entry_questions_url(act)
  end

  test "create under the selected topic" do
    topic = Topic.create!(name: "Logística")
    other_topic = Topic.create!(name: "Comunicación")

    assert_difference "Question.count", 1 do
      post questions_url(topic_id: topic.id), params: {
        question: { body: "¿Dónde está el material?", act_id: activities(:opening_act).id, topic_id: other_topic.id }
      }
    end

    question = Question.order(:id).last
    assert_equal topic, question.topic
    assert_nil question.act_id
    assert_redirected_to questions_url(topic_id: topic.id)
  end

  test "ignore topic selection for act questions" do
    act = activities(:opening_act)
    topic = Topic.create!(name: "Logística")

    assert_difference "Question.count", 1 do
      post schedule_entry_questions_url(act, topic_id: topic.id), params: { question: { body: "¿Quién presenta?" } }
    end

    question = Question.order(:id).last
    assert_equal act.id, question.act_id
    assert_nil question.topic_id
    assert_redirected_to schedule_entry_questions_url(act)
  end

  test "protect question associations and answers" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(act_id: activities(:opening_act).id, body: "Pregunta original", answer: "Respuesta original")
    original_attributes = question.attributes.except("body", "updated_at")

    patch question_url(question), params: {
      question: { body: "Pregunta actualizada", act_id: activities(:closing_act).id, topic_id: topic.id, answer: "Respuesta manipulada" }
    }

    assert_response :see_other
    assert_equal "Pregunta actualizada", question.reload.body
    assert_equal original_attributes, question.attributes.except("body", "updated_at")
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
      url = question_url(question, topic_id: other_topic.id, schedule_entry_id: activities(:closing_act).id)
      patch url, params: { question: { body: "Texto actualizado" } }
      assert_response :see_other
      assert_redirected_to destination
      assert_equal "Texto actualizado", question.reload.body

      assert_difference "Question.count", -1 do
        delete url
      end
      assert_response :see_other
      assert_redirected_to destination
      assert_not Question.exists?(question.id)
    end
  end
end

require "application_request_test_case"

class TopicsControllerTest < ApplicationRequestTestCase
  test "protect question assignments" do
    topic = Topic.create!(name: "Logística")
    assigned_question = Question.create!(body: "Pregunta del tema", topic: topic)
    unassigned_question = Question.create!(body: "Pregunta sin tema")
    original_questions = [ assigned_question, unassigned_question ].map(&:attributes)

    patch topic_url(topic), params: { topic: { name: "Materiales", question_ids: [ unassigned_question.id ] } }

    assert_redirected_to topics_url
    assert_equal "Materiales", topic.reload.name
    assert_equal original_questions, [ assigned_question, unassigned_question ].map { |question| question.reload.attributes }
  end

  test "reject an unknown topic" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "Pregunta del tema", topic: topic)
    original_topic = topic.attributes
    original_question = question.attributes
    unknown_id = topic.id + 1

    assert_no_difference [ "Topic.count", "Question.count" ] do
      get edit_topic_url(unknown_id)
      assert_response :not_found
      patch topic_url(unknown_id), params: { topic: { name: "Tema manipulado" } }
      assert_response :not_found
      delete topic_url(unknown_id)
      assert_response :not_found
    end

    assert_equal original_topic, topic.reload.attributes
    assert_equal original_question, question.reload.attributes
  end
end

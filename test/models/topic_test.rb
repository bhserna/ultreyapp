require "test_helper"

class TopicTest < ActiveSupport::TestCase
  test "keep questions when deleting a topic" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(topic: topic, body: "¿Dónde está el material?", answer: "En la bodega.")

    assert_no_difference "Question.count" do
      topic.destroy!
    end

    assert_not Topic.exists?(topic.id)
    assert_nil question.reload.topic_id
    assert_equal "¿Dónde está el material?", question.body
    assert_equal "En la bodega.", question.answer
  end
end

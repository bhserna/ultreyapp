require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  test "require a body" do
    question = Question.new(body: " ")

    assert_not question.valid?
    assert question.errors.of_kind?(:body, :blank)
  end

  test "normalize blank answers" do
    [ nil, "", "  \n  " ].each do |answer|
      question = Question.new(body: "¿Quién coordina?", answer: answer)

      assert_nil question.answer
    end
  end

  test "resolve only act references" do
    act = activities(:opening_act)
    question = Question.new(body: "¿Quién coordina?", act_id: act.id)

    assert_equal act, question.activity
    question.act_id = nil
    assert_nil question.activity

    [ activities(:reception), activities(:chair_setup) ].each do |activity|
      question.act_id = activity.id
      assert_raises(ActiveRecord::RecordNotFound) { question.activity }
    end
  end
end

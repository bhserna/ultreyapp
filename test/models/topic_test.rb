require "test_helper"

class TopicTest < ActiveSupport::TestCase
  test "requires a name in the database without model validation" do
    topic = Topic.new

    assert topic.valid?
    assert_raises(ActiveRecord::NotNullViolation) { topic.save! }
  end
end

require "test_helper"

class TopicsControllerTest < ActionDispatch::IntegrationTest
  test "lists topics and the creation form" do
    later_topic = Topic.create!(name: "Transmisión")
    earlier_topic = Topic.create!(name: "Escenario")

    get topics_url

    assert_response :success
    assert_select "h1", text: "Editar temas"
    assert_select ".site-nav a[aria-current='page']", text: "Preguntas generales"
    assert_equal [ "Escenario", "Transmisión" ], css_select(".topics__management-item .topics__name").map { |node| node.text.strip }
    assert_select "turbo-frame#topic_#{earlier_topic.id} a[href=?]", edit_topic_path(earlier_topic)
    assert_select "turbo-frame#topic_#{later_topic.id} form[action=?]", topic_path(later_topic)
    assert_select "form[action=?] input[name='topic[name]'][required]", topics_path
  end

  test "creates a topic and returns to the list" do
    assert_difference("Topic.count", 1) do
      post topics_url, params: { topic: { name: "Logística" } }
    end

    assert_redirected_to topics_url
    assert_equal "Logística", Topic.order(:id).last.name
  end

  test "edits a topic inside its turbo frame" do
    topic = Topic.create!(name: "Logística")

    get edit_topic_url(topic)

    assert_response :success
    assert_select "turbo-frame#topic_#{topic.id} form[action=?]", topic_path(topic) do
      assert_select "input[name='topic[name]'][value=?][required]", "Logística"
    end

    patch topic_url(topic), params: { topic: { name: "Materiales" } }

    assert_redirected_to topics_url
    assert_equal "Materiales", topic.reload.name
  end

  test "deleting a topic keeps its questions without a topic" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "¿Dónde está el material?", topic: topic)

    assert_difference("Topic.count", -1) do
      assert_no_difference("Question.count") do
        delete topic_url(topic)
      end
    end

    assert_redirected_to topics_url
    assert_nil question.reload.topic_id
  end
end

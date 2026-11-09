require "application_system_test_case"

class TopicsTest < ApplicationSystemTestCase
  test "create a topic" do
    visit questions_path
    within(".topics") { click_link "Editar" }

    click_button "Nuevo tema"
    fill_in "Nombre", with: "Logística"
    click_button "Guardar tema"

    assert_selector :topic_item, "Logística"
    click_link "← Volver a las preguntas generales"
    within(".topics") { click_link "Logística" }
    assert_selector :selected_topic, "Logística"
  end

  test "rename a topic" do
    topic = Topic.create!(name: "Logística")
    question = Question.create!(body: "¿Dónde guardamos el material?", topic: topic)
    visit topics_path

    within(:topic_item, topic.name) do
      click_link "Editar tema #{topic.name}"
      fill_in "Nombre", with: "Materiales"
      click_button "Guardar cambios"
    end

    assert_selector :topic_item, "Materiales"
    assert_no_selector :topic_item, topic.name
    click_link "← Volver a las preguntas generales"
    within(".topics") { click_link "Materiales" }
    assert_selector :selected_topic, "Materiales"
    assert_selector :question, question.body
  end

  test "cancel editing a topic" do
    topic = Topic.create!(name: "Logística")
    visit topics_path

    within(:topic_item, topic.name) do
      click_link "Editar tema #{topic.name}"
      fill_in "Nombre", with: "Materiales"
      click_link "Cancelar"
    end

    assert_selector :topic_item, topic.name
    assert_no_selector :topic_item, "Materiales"
  end

  test "delete a topic" do
    topic = Topic.create!(name: "Materiales")
    question = Question.create!(body: "¿Dónde guardamos el material?", topic: topic)
    visit topics_path

    within(:topic_item, topic.name) do
      accept_confirm { click_button "Eliminar tema #{topic.name}" }
    end

    assert_no_selector :topic_item, topic.name
    click_link "← Volver a las preguntas generales"
    assert_selector :selected_topic, "Sin tema"
    assert_selector :question, question.body
    within(".topics") { assert_no_link topic.name }
  end
end

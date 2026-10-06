require "application_system_test_case"

class ActivityQuestionsTest < ApplicationSystemTestCase
  test "edits and answers an activity question through shallow routes" do
    question = Question.create!(schedule_entry_id: 3, body: "¿Quién coordina?")

    visit schedule_entry_questions_path(3)

    within(".questions__item", text: question.body) do
      assert_link "Editar", href: edit_question_path(question)
      click_link "Editar"
    end
    assert_selector ".site-nav a[aria-current='page']", text: "Programa"
    assert_selector "form[action='#{question_path(question)}']"
    fill_in "Pregunta", with: "¿Quién dirige?"
    click_button "Guardar cambios"
    assert_text "¿Quién dirige?"

    within(".questions__item", text: "¿Quién dirige?") do
      assert_link "Responder", href: edit_question_answer_path(question)
      click_link "Responder"
    end
    assert_selector "form[action='#{question_answer_path(question)}']"
    fill_in "Respuesta", with: "El equipo de coordinación."
    click_button "Guardar respuesta"
    assert_text "El equipo de coordinación."
    assert_equal 3, question.reload.schedule_entry_id
  end

  test "clears a blank answer on an activity question" do
    question = Question.create!(schedule_entry_id: 3, body: "¿Quién coordina?", answer: "El equipo de coordinación.")

    visit schedule_entry_questions_path(3)

    within(".questions__item", text: question.body) do
      click_link "Editar respuesta"
    end
    fill_in "Respuesta", with: ""
    click_button "Guardar respuesta"

    assert_current_path schedule_entry_questions_path(3)
    assert_link "Responder"
    assert_no_selector ".questions__answer"
    assert_nil question.reload.answer
  end
end

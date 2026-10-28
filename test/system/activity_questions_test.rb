require "application_system_test_case"

class ActivityQuestionsTest < ApplicationSystemTestCase
  test "edits and answers a question without changing its activity" do
    question = Question.create!(schedule_entry_id: 3, body: "¿Quién coordina?")

    visit schedule_entry_questions_path(3)

    within(:question, question.body) { click_link "Editar" }
    assert_selector ".site-nav a[aria-current='page']", text: "Programa"
    fill_in "Pregunta", with: "¿Quién dirige?"
    click_button "Guardar cambios"

    assert_no_selector :question, question.body
    within(:question, "¿Quién dirige?") { click_link "Responder" }
    fill_in "Respuesta", with: "El equipo de coordinación."
    click_button "Guardar respuesta"

    within(:question, "¿Quién dirige?") do
      assert_text "El equipo de coordinación."
    end
    assert_equal 3, question.reload.schedule_entry_id
  end

  test "clears a blank answer on an activity question" do
    question = Question.create!(schedule_entry_id: 3, body: "¿Quién coordina?", answer: "El equipo de coordinación.")

    visit schedule_entry_questions_path(3)

    within(:question, question.body) { click_link "Editar respuesta" }
    fill_in "Respuesta", with: ""
    click_button "Guardar respuesta"

    assert_current_path schedule_entry_questions_path(3)
    within(:question, question.body) do
      assert_link "Responder"
      assert_no_selector ".questions__answer"
    end
    assert_nil question.reload.answer
  end
end

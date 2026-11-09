require "application_system_test_case"

class ActsTest < ApplicationSystemTestCase
  test "show act details" do
    act = activities(:opening_act)
    ProductionDetail.create!(act_id: act.id, executors: "Equipo de bienvenida", audio: "Micrófono principal", notes: "Notas del acto")

    visit schedule_entry_path(act)

    assert_selector "h1", text: act.title
    assert_selector :activity_metadata, "Inicio", text: act.start_time
    within(:activity_metadata, "Comisiones") { assert_link "Programa" }
    assert_text "Equipo de bienvenida"
    assert_text "Micrófono principal"
    assert_text "Notas del acto"
  end

  test "create an act question" do
    act = activities(:opening_act)
    general_question = Question.create!(body: "Pregunta general")
    other_question = Question.create!(act_id: activities(:closing_act).id, body: "Pregunta de otro acto")
    visit schedule_entry_path(act)

    within("turbo-frame#questions") do
      click_button "Nueva pregunta"
      fill_in "Nueva pregunta", with: "¿Quién presenta el acto?"
      click_button "Guardar pregunta"

      assert_selector :question, "¿Quién presenta el acto?"
      assert_no_selector :question, general_question.body
      assert_no_selector :question, other_question.body
    end
    assert_equal act.id, Question.find_by!(body: "¿Quién presenta el acto?").act_id

    visit questions_path
    assert_no_selector :question, "¿Quién presenta el acto?"
  end

  test "filter from a commission link" do
    act = activities(:opening_act)
    visit schedule_entry_path(act)

    within(:activity_metadata, "Comisiones") { click_link "Programa" }

    assert_select "Comisión", selected: "Programa"
    assert_selector "nav a[aria-current='page']", text: act.day
    assert_selector :schedule_act, act.title
    assert_no_selector :schedule_act, activities(:closing_act).title
  end
end

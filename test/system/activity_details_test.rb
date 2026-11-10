require "application_system_test_case"

class ActivityDetailsTest < ApplicationSystemTestCase
  test "create and edit act details" do
    assert_details_flow(activities(:opening_act), schedule_entry_path(activities(:opening_act)))
  end

  test "create and edit operation details using the internal activity ID" do
    operation = activities(:reception)
    assert_not_equal operation.source_id, operation.id

    assert_details_flow(operation, operational_activity_path(operation.source_id))
  end

  test "create and edit preparation action details and return to the action" do
    action = activities(:chair_setup)

    assert_details_flow(action, preparation_path(action.preparation_id))
    assert_equal "activity_#{action.id}", URI.parse(current_url).fragment
    assert_equal "Programa", activities(:microphone_setup).commissions.first
  end

  test "cancel editing without changing details" do
    [ activities(:opening_act), activities(:reception), activities(:chair_setup) ].each do |activity|
      detail = activity.activity_detail || activity.create_activity_detail!(notes: "Original notes")
      original = detail.attributes
      visit edit_activity_activity_detail_path(activity)
      fill_in "Notas", with: "Unsaved notes"
      click_link "Cancelar"

      assert_no_selector "form textarea"
      assert_equal original, detail.reload.attributes
    end
  end

  private

  def assert_details_flow(activity, return_path)
    activity.activity_detail&.destroy!
    original_activity = activity.reload.attributes
    production = ProductionDetail.create!(act_id: activity.id, notes: "Legacy notes", audio: "Legacy audio")
    original_production = production.attributes
    visit return_path

    within(:activity_details, activity.id) do
      assert_text "Todavía no hay detalles para esta actividad."
      assert_no_text "Legacy notes"
      click_link "Agregar detalles"
    end
    assert_current_path new_activity_activity_detail_path(activity)
    assert_no_field "Comisión"
    fill_in "Descripción", with: "Instructions for this activity"
    fill_in "Ejecuta", with: "Equipo de bienvenida"
    fill_in "Audio", with: "Micrófono principal"
    fill_in "Videos o pistas", with: "Welcome video"
    fill_in "Notas", with: "Primera indicación\nSegunda indicación"
    fill_in "Preguntas para la Arena", with: "Which entrance?"
    click_button "Guardar detalles"

    assert_current_path return_path, ignore_query: true
    within(:activity_details, activity.id) do
      assert_text "Instructions for this activity"
      assert_text "Equipo de bienvenida"
      assert_text "Micrófono principal"
      assert_text "Welcome video"
      assert_text "Primera indicación"
      assert_text "Segunda indicación"
      assert_text "Which entrance?"
      assert_no_selector "h3", text: "Iluminación de sala"
      click_link "Editar detalles"
    end

    assert_current_path edit_activity_activity_detail_path(activity)
    assert_no_field "Comisión"
    assert_field "Audio", with: "Micrófono principal"
    assert_field "Videos o pistas", with: "Welcome video"
    fill_in "Audio", with: "Dos micrófonos"
    fill_in "Notas", with: ""
    click_button "Guardar detalles"

    assert_current_path return_path, ignore_query: true
    within(:activity_details, activity.id) do
      assert_text "Dos micrófonos"
      assert_no_text "Micrófono principal"
      assert_no_text "Primera indicación"
      assert_no_selector "h3", text: "Notas", exact_text: true
      assert_no_link "Agregar detalles"
    end

    assert_equal "Dos micrófonos", activity.reload.activity_detail.audio
    assert_equal original_activity, activity.attributes
    assert_equal original_production, production.reload.attributes
  end
end

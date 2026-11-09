require "application_system_test_case"

class ProductionDetailsTest < ApplicationSystemTestCase
  test "create and edit production details" do
    act = activities(:opening_act)
    visit schedule_entry_path(act)
    assert_text "Todavía no hay detalles de producción para esta actividad."

    click_link "Agregar detalles de producción"
    fill_in "Ejecuta", with: "Equipo de bienvenida"
    fill_in "Audio", with: "Micrófono principal"
    fill_in "Notas", with: "Primera indicación\nSegunda indicación"
    click_button "Guardar detalles de producción"

    assert_current_path schedule_entry_path(act)
    within(:production_details) do
      assert_text "Equipo de bienvenida"
      assert_text "Micrófono principal"
      assert_text "Primera indicación"
      assert_text "Segunda indicación"
      click_link "Editar detalles de producción"
    end

    assert_field "Audio", with: "Micrófono principal"
    fill_in "Audio", with: "Dos micrófonos"
    click_button "Guardar detalles de producción"

    within(:production_details) do
      assert_text "Dos micrófonos"
      assert_no_text "Micrófono principal"
    end

    assert_no_link "Agregar detalles de producción"
  end
end

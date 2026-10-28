require "application_system_test_case"

class ProductionDetailsTest < ApplicationSystemTestCase
  test "creates reads edits and deletes production details from an activity" do
    visit schedule_entry_path(3)
    assert_text "Todavía no hay detalles de producción para esta actividad."
    click_link "Agregar detalles de producción"

    fields = {
      "Ejecuta" => [ "executors", "Equipo EyA" ],
      "Pantalla" => [ "screen", "Video de bienvenida" ],
      "Audio" => [ "audio", "Dos micrófonos" ],
      "Iluminación de sala" => [ "room_lighting", "Sala al 30%" ],
      "Iluminación de escenario" => [ "stage_lighting", "Luz frontal" ],
      "Iluminación de pasillos" => [ "aisle_lighting", "Pasillos visibles" ],
      "Requerimientos" => [ "requirements", "Diez sillas" ],
      "Notas" => [ "notes", "Primera línea\nSegunda línea" ],
      "Radios" => [ "radios", "2 radios, canal 3" ],
      "Pendientes por confirmar" => [ "pending_confirmations", "Confirmar proveedor" ]
    }
    fields.each { |label, (_, value)| fill_in label, with: value }
    click_button "Guardar detalles de producción"

    assert_current_path schedule_entry_path(3)
    detail = ProductionDetail.find_by!(schedule_entry_id: 3)
    fields.each_value do |attribute, value|
      assert_equal value, detail.public_send(attribute)
      value.lines.each { |line| assert_text line.strip }
    end
    assert_no_link "Agregar detalles de producción"

    click_link "Editar detalles de producción"
    fields.each do |label, (_, value)|
      assert_field label, with: value
      fill_in label, with: "Actualizado: #{value}"
    end
    click_button "Guardar detalles de producción"
    assert_current_path schedule_entry_path(3)
    detail.reload
    fields.each_value do |attribute, value|
      assert_equal "Actualizado: #{value}", detail.public_send(attribute)
      assert_text "Actualizado: #{value.lines.first.strip}"
    end

    visit schedule_entry_path(4)
    assert_text "Todavía no hay detalles de producción para esta actividad."
    assert_no_text "Equipo EyA"

    visit schedule_entry_path(3)
    accept_confirm { click_button "Eliminar detalles de producción" }
    assert_text "Todavía no hay detalles de producción para esta actividad."
    assert_not ProductionDetail.exists?(detail.id)
  end
end

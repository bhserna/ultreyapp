require "test_helper"
require_relative "../support/app_selectors"

class DetailFieldSelectorTest < ActiveSupport::TestCase
  setup do
    @document = Capybara.string(<<~HTML)
      <section id="production">
        <p>Descripción sin encabezado</p>
        <h3>Pantalla</h3>
        <p>Video de bienvenida</p>
        <h3>Notas</h3>
        <p>Primera línea</p>
        <p>Segunda <strong>línea</strong></p>
        <h3>Audio</h3>
        <p>Dos micrófonos</p>
        <h3>Audio de escenario</h3>
        <p>Prueba de sonido</p>
      </section>
      <section id="operation">
        <h3>Notas</h3>
        <p>Notas de otra actividad</p>
      </section>
    HTML
  end

  test "finds the content under the requested heading rather than any paragraph" do
    assert @document.has_selector?(:detail_field, "Pantalla", exact_text: "Video de bienvenida")
    assert_not @document.has_selector?(:detail_field, "Audio", text: "Video de bienvenida")
    assert_not @document.has_selector?(:detail_field, "Pantalla", text: "Descripción sin encabezado")
    assert_not @document.has_selector?(:detail_field, "Campo inexistente")
  end

  test "returns all paragraphs of a field and stops at the next heading" do
    production = @document.find("#production")
    paragraphs = production.all(:detail_field, "Notas").map(&:text)

    assert_equal [ "Primera línea", "Segunda línea" ], paragraphs
    assert_not production.has_selector?(:detail_field, "Notas", text: "Dos micrófonos")
  end

  test "matches the complete heading even when another heading shares its prefix" do
    assert_equal [ "Dos micrófonos" ], @document.all(:detail_field, "Audio").map(&:text)
    assert_not @document.has_selector?(:detail_field, "Audio", text: "Prueba de sonido")
  end

  test "respects the surrounding section when headings are repeated" do
    operation = @document.find("#operation")

    assert_equal [ "Notas de otra actividad" ], operation.all(:detail_field, "Notas").map(&:text)
    assert_not operation.has_selector?(:detail_field, "Notas", text: "Primera línea")
  end
end

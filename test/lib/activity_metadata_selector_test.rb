require "test_helper"
require_relative "../support/app_selectors"

class ActivityMetadataSelectorTest < ActiveSupport::TestCase
  setup do
    @document = Capybara.string(<<~HTML)
      <header>
        <dl class="page__details">
          <div><dt>Inicio</dt><dd>07:00</dd></div>
          <div><dt>Inicio de preparación</dt><dd>06:30</dd></div>
          <div><dt>Fin</dt><dd>08:00</dd></div>
          <div><dt>Comisiones</dt><dd><a href="/?commission=Programa">Programa</a></dd></div>
        </dl>
      </header>
      <section>
        <dl class="page__details">
          <div><dt>Inicio</dt><dd>09:00</dd></div>
        </dl>
      </section>
      <dl>
        <dt>Inicio</dt><dd>10:00</dd>
      </dl>
    HTML
  end

  test "matches the exact label and excludes values belonging to other metadata" do
    header = @document.find("header")

    assert_equal [ "07:00" ], header.all(:activity_metadata, "Inicio").map(&:text)
    assert_not header.has_selector?(:activity_metadata, "Inicio", text: "06:30")
    assert_not header.has_selector?(:activity_metadata, "Inicio", text: "08:00")
    assert_not header.has_selector?(:activity_metadata, "Día")
  end

  test "respects the current scope and excludes unrelated definition lists" do
    section = @document.find("section")

    assert_equal [ "09:00" ], section.all(:activity_metadata, "Inicio").map(&:text)
    assert_equal [ "07:00", "09:00" ], @document.all(:activity_metadata, "Inicio").map(&:text)
  end

  test "returns the value node so that commission links can be scoped within it" do
    commissions = @document.find(:activity_metadata, "Comisiones")

    assert_equal "dd", commissions.tag_name
    assert commissions.has_selector?(:link, "Programa", href: "/?commission=Programa")
  end
end

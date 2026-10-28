require "test_helper"
require_relative "../support/app_selectors"

class RelatedActSelectorTest < ActiveSupport::TestCase
  setup do
    @document = Capybara.string(<<~HTML)
      <ul class="related-links">
        <li><a href="/schedule_entries/1">
          <span class="related-links__label">Acto 1</span>
          <span class="related-links__title">Proyección Video Inicio</span>
        </a></li>
        <li><a href="/schedule_entries/13">
          <span class="related-links__label">Acto 10</span>
          <span class="related-links__title">Seguimiento del Acto 1</span>
        </a></li>
      </ul>
      <a href="/other"><span class="related-links__label">Acto 1</span></a>
    HTML
  end

  test "identifies the link by its exact act label rather than its title or label prefix" do
    links = @document.all(:related_act, "Acto 1")

    assert_equal 1, links.size
    assert_equal "a", links.first.tag_name
    assert_equal "/schedule_entries/1", links.first[:href]
  end

  test "filters the destination without confusing act numbers with route IDs" do
    assert @document.has_selector?(:related_act, "Acto 10", href: "/schedule_entries/13")
    assert_not @document.has_selector?(:related_act, "Acto 10", href: "/schedule_entries/10")
  end

  test "allows counting all related acts while excluding links outside the related list" do
    assert @document.has_selector?(:related_act, count: 2)
    assert_not @document.has_selector?(:related_act, href: "/other")
  end
end

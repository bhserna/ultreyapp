require "test_helper"
require_relative "../../../lib/rubocop/cop/ultreya/prefer_registered_selector"

class PreferRegisteredSelectorTest < ActiveSupport::TestCase
  test "directs application CSS selectors to their registered equivalents" do
    examples = {
      "tbody tr.schedule__act" => :schedule_act,
      "tr.schedule__preparation" => :schedule_preparation,
      "tr[data-preparation-id='2']" => :schedule_preparation,
      "tr.schedule__operation" => :schedule_operation,
      "tr[data-operational-activity-id='7']" => :schedule_operation,
      "tr.schedule__phase th" => :schedule_phase,
      "tbody[data-phase='program']" => :schedule_phase,
      ".questions__item" => :question,
      ".topics__management-item" => :topic_item,
      ".topics__tab[aria-current='page']" => :selected_topic
    }

    examples.each do |css, selector|
      offenses = inspect_source("assert_selector #{css.inspect}")

      assert_equal 1, offenses.size, css
      assert_includes offenses.first.message, ":#{selector}", css
      assert_equal css.inspect, offenses.first.location.source
    end
  end

  test "new selector definitions are available to Capybara and the cop without another mapping" do
    previous_checksum = cop.external_dependency_checksum
    AppSelectors.add(:lint_example, replaces_css: /\.lint-example\b/) do
      css { ".lint-example" }
    end

    assert_not_equal previous_checksum, cop.external_dependency_checksum
    assert_equal "Example", Capybara.string('<p class="lint-example">Example</p>').find(:lint_example).text
    offenses = inspect_source('assert_selector ".lint-example"')
    assert_equal 1, offenses.size
    assert_includes offenses.first.message, ":lint_example"
    assert_empty inspect_source("assert_selector :lint_example")
  ensure
    Capybara::Selector.remove(:lint_example)
    AppSelectors.css_replacements.delete(:lint_example)
  end

  test "checks each supported Capybara method including explicit CSS and page receivers" do
    %w[ within find all assert_selector assert_no_selector ].each do |method|
      assert_equal 1, inspect_source("#{method} '.questions__item'").size, method
      assert_equal 1, inspect_source("page.#{method} :css, '.questions__item'").size, method
    end
  end

  test "reports all registered alternatives in a combined selector" do
    offenses = inspect_source('assert_no_selector "tr.schedule__act, tr.schedule__preparation"')

    assert_equal 1, offenses.size
    assert_includes offenses.first.message, ":schedule_act, :schedule_preparation"
  end

  test "rejects positional cells inside schedule scopes" do
    sources = [
      'within(:schedule_act, "Comida") { assert_selector "td:nth-child(2)", text: "14:25" }',
      'within("tr.schedule__operation") { find("td:first-child") }',
      'within(:css, "tr.schedule__act") { find("td:nth-child(2)") }',
      'within(:schedule_phase, :program) { within(:schedule_preparation, 2) { all("td:nth-child(3)") } }'
    ]

    sources.each do |source|
      offenses = inspect_source(source)
      assert offenses.any? { |offense| offense.message.include?(":schedule_cell") }, source
    end
  end

  test "allows registered selectors and CSS that has no registered equivalent" do
    sources = [
      'within(:question, "¿Quién coordina?") { click_link "Editar" }',
      "assert_selector :schedule_act, count: 19",
      'assert_selector ".questions__answer"',
      'assert_selector ".page__header.page__header--flush"',
      'assert_selector ".schedule__activity"',
      'assert_selector ".topics__tab"',
      'assert_selector ".questions__item-extra"',
      'assert_selector ".schedule__act-extra"',
      'within(".other-table") { assert_selector "td:nth-child(2)" }',
      'within(:schedule_unknown) { assert_selector "td:nth-child(2)" }',
      'within(".schedule__activity") { assert_selector "td:nth-child(2)" }',
      'evaluate_script("getComputedStyle(document.querySelector(\'.schedule__preparation\')).backgroundColor")',
      "assert_selector dynamic_selector",
      'assert_selector ".questions__item[data-id=\'#{question.id}\']"'
    ]

    sources.each do |source|
      assert_empty inspect_source(source), source
    end
  end

  test "is enabled only for system tests" do
    assert cop.relevant_file?(Rails.root.join("test/system/general_questions_test.rb").to_s)
    assert_not cop.relevant_file?(Rails.root.join("test/controllers/questions_controller_test.rb").to_s)
    assert_not cop.relevant_file?(Rails.root.join("test/support/question_selectors.rb").to_s)
  end

  private

  def config
    @config ||= RuboCop::ConfigLoader.load_file(Rails.root.join(".rubocop.yml").to_s)
  end

  def cop
    RuboCop::Cop::Ultreya::PreferRegisteredSelector.new(config)
  end

  def inspect_source(source)
    processed_source = RuboCop::ProcessedSource.new(
      source.dup, 3.4, Rails.root.join("test/system/example_test.rb").to_s
    )
    team = RuboCop::Cop::Team.new([ cop ], config, raise_error: true)
    team.investigate(processed_source).offenses
  end
end

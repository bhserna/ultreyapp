require "capybara"

module AppSelectors
  def self.add(name, replaces_css: nil, within: [], &block)
    Capybara.add_selector(name, &block)
    css_replacements[name] = { pattern: replaces_css, within: within } if replaces_css
  end

  def self.css_replacements
    @css_replacements ||= {}
  end
end

require_relative "schedule_selectors"
require_relative "question_selectors"
require_relative "activity_selectors"

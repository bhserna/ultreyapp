require "test_helper"
require_relative "support/app_selectors"
require_relative "support/event_fixtures"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include EventFixtures

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
end

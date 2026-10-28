require "test_helper"
require_relative "support/schedule_selectors"
require_relative "support/question_selectors"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
end

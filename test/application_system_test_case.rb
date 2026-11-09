require "test_helper"
require_relative "support/app_selectors"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  self.fixture_paths = [ Rails.root.join("test/system/fixtures") ]
  # Distinct set names avoid cache collisions with model and controller fixtures.
  self.fixture_table_names = %w[system_activities system_preparations]
  set_fixture_class system_activities: Activity, system_preparations: Preparation
  self.fixture_sets = { "activities" => "system_activities", "preparations" => "system_preparations" }

  teardown { ActiveRecord::FixtureSet.reset_cache }

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]
end

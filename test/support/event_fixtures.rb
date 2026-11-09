module EventFixtures
  extend ActiveSupport::Concern

  included do
    self.fixture_paths = [ Rails.root.join("test/scenario_fixtures") ]
    # Distinct set names avoid cache collisions with the larger model fixtures.
    self.fixture_table_names = %w[scenario_activities scenario_preparations]
    set_fixture_class scenario_activities: Activity, scenario_preparations: Preparation
    self.fixture_sets = { "activities" => "scenario_activities", "preparations" => "scenario_preparations" }

    teardown { ActiveRecord::FixtureSet.reset_cache }
  end
end

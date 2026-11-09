require "test_helper"
require_relative "support/event_fixtures"

class ApplicationRequestTestCase < ActionDispatch::IntegrationTest
  include EventFixtures
end

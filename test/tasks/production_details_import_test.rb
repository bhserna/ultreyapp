require "test_helper"
require "rake"

class ProductionDetailsImportTest < ActiveSupport::TestCase
  test "imports every production field under the act identified by the source" do
    source = YAML.safe_load_file(Rails.root.join("config/data/production_details.yml")).fetch("production_details")
    Rails.application.load_tasks unless Rake::Task.task_defined?("production_details:import")
    Rake::Task["production_details:import"].reenable

    capture_io { Rake::Task["production_details:import"].invoke }

    assert_equal source.size, ProductionDetail.count
    source.each do |entry|
      detail = ProductionDetail.find_by!(schedule_entry_id: entry.fetch("schedule_entry_id"))
      expected = entry.fetch("attributes")

      assert_equal expected, detail.attributes.slice(*expected.keys), "Production details for act #{entry.fetch('schedule_entry_id')}"
    end
  end
end

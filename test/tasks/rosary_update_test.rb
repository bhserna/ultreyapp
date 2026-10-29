require "test_helper"
require "rake"

class RosaryUpdateTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("data_updates:rosary_executors")
    @task = Rake::Task["data_updates:rosary_executors"]
    @detail = ProductionDetail.create!(schedule_entry_id: 22,
      executors: "Yola y Beba / 5 sacerdotes / Jeseed", notes: "Manual production notes")
  end

  test "previews by default without changing any attributes" do
    before = @detail.attributes

    output = run_task

    assert_includes output, "Preview only"
    assert_includes output, "Laicos y 5 sacerdotes"
    assert_equal before, @detail.reload.attributes
  end

  test "updates only the approved field and leaves other records untouched" do
    other = ProductionDetail.create!(schedule_entry_id: 21, executors: "Manual team")
    before = @detail.attributes.except("executors", "updated_at")
    other_before = other.attributes

    assert_no_difference("ProductionDetail.count") { run_task("apply") }

    assert_equal "Yola y Beba / Laicos y 5 sacerdotes / Jeseed", @detail.reload.executors
    assert_equal before, @detail.attributes.except("executors", "updated_at")
    assert_equal other_before, other.reload.attributes
    source = YAML.safe_load_file(Rails.root.join("config/data/production_details.yml"))
    expected = source.fetch("production_details").find { |entry| entry.fetch("schedule_entry_id") == 22 }
    assert_equal expected.fetch("attributes").fetch("executors"), @detail.executors
  end

  test "does nothing on subsequent executions" do
    run_task("apply")
    before = @detail.reload.attributes

    assert_includes run_task("apply"), "Already updated"
    assert_equal before, @detail.reload.attributes
  end

  test "rejects manual edits rather than overwriting them in either mode" do
    @detail.update!(executors: "Manually edited team")
    before = @detail.reload.attributes

    [ nil, "apply" ].each do |mode|
      error = assert_raises(RuntimeError) { run_task(mode) }
      assert_includes error.message, "Conflict"
      assert_equal before, @detail.reload.attributes
    end
  end

  test "does not create missing records" do
    @detail.destroy!

    assert_no_difference("ProductionDetail.count") do
      assert_raises(ActiveRecord::RecordNotFound) { run_task("apply") }
    end
  end

  test "rejects unsupported modes without writing" do
    before = @detail.attributes

    assert_raises(ArgumentError) { run_task("true") }
    assert_equal before, @detail.reload.attributes
  end

  private

  def run_task(mode = nil)
    @task.reenable
    capture_io { @task.invoke(mode) }.first
  end
end

require "test_helper"
require "rake"

class QuestionsImportTest < ActiveSupport::TestCase
  test "imports activity questions and answers under the acts identified by the source" do
    source = YAML.safe_load_file(Rails.root.join("config/data/questions.yml"))
    Rails.application.load_tasks unless Rake::Task.task_defined?("questions:import")
    Rake::Task["questions:import"].reenable

    capture_io { Rake::Task["questions:import"].invoke }

    expected = source.fetch("schedule_entries").flat_map do |entry|
      entry.fetch("questions").map do |item|
        [ entry.fetch("id"), item.fetch("question"), item["answer"] ]
      end
    end
    actual = Question.where.not(schedule_entry_id: nil).order(:id).pluck(:schedule_entry_id, :body, :answer)

    assert_equal expected, actual
  end
end

require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "includes only numbered acts from yellow Act cells in spreadsheet order" do
    entries = Activity.acts

    assert entries.all? { |entry| entry.kind == "act" }
    assert entries.none? { |entry| entry.is_a?(ApplicationRecord) }
    source = YAML.safe_load_file(Rails.root.join("config/data/schedule.yml"))

    assert_equal (1..31).to_a, entries.map(&:id)
    by_sheet = source.group_by { |entry| entry.fetch("source_sheet") }
    assert_equal [ "1er, día 15 Nov", "2do. día 16 Nov" ], by_sheet.keys
    assert_equal [ 29, 30, 36, 42, 47, 49, 53, 54, 55, 58, 60, 64, 68, 71, 76, 80, 84, 88, 92 ],
      by_sheet.fetch("1er, día 15 Nov").map { |entry| entry.fetch("source_row") }
    assert_equal [ 5, 6, 9, 13, 17, 21, 25, 29, 33, 37, 39, 40 ],
      by_sheet.fetch("2do. día 16 Nov").map { |entry| entry.fetch("source_row") }
    assert_equal (1..28).to_a - [ 7 ], entries.map(&:act_number).grep(Integer)
    assert_equal %w[7.1 7.2 7.3 7.4], entries.map(&:act_number).grep(String)
    assert_equal source.map { |entry| entry.fetch("activity") }, entries.map(&:title)
    assert_equal 1, Activity.find(1).act_number
    assert_equal "7.4", Activity.find(10).act_number
    assert_equal 17, Activity.find(20).act_number
    assert_equal 28, Activity.find(31).act_number
    assert_equal "14:25", Activity.find(30).start_time
    assert_equal "08:30", Activity.find(20).start_time
    assert_equal "08:35", Activity.find(20).end_time
    assert_equal "Palabras de Presidente Mundial / Agradecimientos Finales", Activity.find(28).title
    assert_equal "12:27", Activity.find(28).start_time
    assert_equal "16:20", Activity.find(12).end_time
    assert_equal "0:30", Activity.find(12).duration
    assert_equal "16:20", Activity.find(13).start_time
    assert_includes Activity.find(12).title, "Esperanza en la enfermedad"
    assert_includes Activity.find(14).title, "Perseverancia como dirigente"
    assert_equal "Animación Coro de Cursillos/ Bendicam", Activity.find(17).title
    assert_equal [ "Domingo 15", "Lunes 16" ], entries.map(&:day).uniq
  end

  test "gives acts and operations unique explicit IDs without renumbering existing acts" do
    activities = Activity.all

    assert_equal 44, activities.size
    assert_equal activities.size, activities.map(&:id).uniq.size
    assert activities.all? { |activity| activity.instance_of?(Activity) }
    assert_equal (1..31).to_a, Activity.acts.map(&:id)
    assert_equal (32..44).to_a, Activity.operations.map(&:id)
    assert_equal (1..13).to_a, Activity.operations.map(&:source_id)
    assert_equal "act", Activity.find(1).kind
    assert_equal "operation", Activity.find("32").kind
    assert_equal "Recepción de Diócesis", Activity.find(32).title
    assert_equal "Recepción de Diócesis", Activity.find_operation_by_source_id("1").title
    assert_nil Activity.find(32).act_number
    assert_raises(ActiveRecord::RecordNotFound) { Activity.find(32, kind: "act") }
    assert_raises(ActiveRecord::RecordNotFound) { Activity.find_operation_by_source_id(32) }
  end

  test "finds acts with stable numeric or route IDs and rejects unknown IDs" do
    assert_equal Activity.find(1).title, Activity.find("1").title
    assert_equal 1, Activity.find("1").id
    assert_equal "program", Activity.find(1).phase
    assert_raises(ActiveRecord::RecordNotFound) { Activity.find(999) }
  end

  test "question references resolve to the renamed activity model" do
    question = Question.create!(schedule_entry_id: 3, body: "Who coordinates this act?")

    assert_instance_of Activity, question.activity
    assert_equal 3, question.activity.id
    assert_equal Activity.find(3).title, question.activity.title
    assert_nil Question.new(body: "General question").activity
  end

  test "question data references only the numbered act on its source row" do
    schedule = YAML.safe_load_file(Rails.root.join("config/data/schedule.yml"))
    source = YAML.safe_load_file(Rails.root.join("config/data/questions.yml"))
    question_entries = source.fetch("schedule_entries")

    assert_equal schedule.map { |entry| entry.fetch("id") }, question_entries.map { |entry| entry.fetch("id") }
    assert_equal 36, question_entries.sum { |entry| entry.fetch("questions").size }
    assert_empty source.fetch("general_questions")
    assert_empty source.fetch("cross_cutting_questions")
    question_entries.zip(schedule).each do |entry, act|
      assert_equal act.fetch("activity"), entry.fetch("act")
      assert_equal [ act.fetch("source_row") ], entry.fetch("source_rows")
      assert_equal act.fetch("source_sheet"), entry.fetch("source_sheet")
    end
    assert_equal 4, question_entries.find { |entry| entry.fetch("id") == 1 }.fetch("questions").size
    assert_equal 1, question_entries.find { |entry| entry.fetch("id") == 3 }.fetch("questions").size
    assert_empty question_entries.find { |entry| entry.fetch("id") == 2 }.fetch("questions")
    assert_equal 2, question_entries.find { |entry| entry.fetch("id") == 19 }.fetch("questions").size
    assert_equal 1, question_entries.find { |entry| entry.fetch("id") == 14 }.fetch("questions").size
    assert_equal 3, question_entries.find { |entry| entry.fetch("id") == 25 }.fetch("questions").size
  end

  test "production data matches the current schedule rows and excludes acts without production content" do
    schedule = YAML.safe_load_file(Rails.root.join("config/data/schedule.yml")).index_by { |entry| entry.fetch("id") }
    details = YAML.safe_load_file(Rails.root.join("config/data/production_details.yml")).fetch("production_details")

    assert_equal (1..31).to_a, details.map { |entry| entry.fetch("schedule_entry_id") }
    details.each do |entry|
      act = schedule.fetch(entry.fetch("schedule_entry_id"))
      assert_equal act.fetch("activity"), entry.fetch("activity")
      assert_equal act.fetch("source_row"), entry.fetch("source_row")
      assert_equal act.fetch("source_sheet"), entry.fetch("source_sheet")
      assert_equal %w[executors screen audio room_lighting stage_lighting aisle_lighting requirements notes radios pending_confirmations].sort,
        entry.fetch("attributes").keys.sort
    end
    vivencia = details.find { |entry| entry.fetch("schedule_entry_id") == 14 }
    assert_equal "Abraham Moreno", vivencia.fetch("attributes").fetch("executors")
    assert_includes vivencia.fetch("attributes").fetch("notes"), "Javier Ayala"
    assert_equal "Daniela Serna", details.find { |entry| entry.fetch("schedule_entry_id") == 23 }.fetch("attributes").fetch("executors")
  end
end

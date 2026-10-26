require "test_helper"

class ScheduleEntryTest < ActiveSupport::TestCase
  test "includes only numbered acts from yellow Act cells in spreadsheet order" do
    entries = ScheduleEntry.all
    source = YAML.safe_load_file(Rails.root.join("config/data/schedule.yml"))

    assert_equal (1..31).to_a, entries.map(&:id)
    assert_equal [29, 30, 36, 42, 47, 49, 53, 54, 55, 58, *(60..80)],
      source.map { |entry| entry.fetch("source_row") }
    assert_equal (1..28).to_a - [7], entries.map(&:act_number).grep(Integer)
    assert_equal %w[7.1 7.2 7.3 7.4], entries.map(&:act_number).grep(String)
    assert_equal 1, ScheduleEntry.find(1).act_number
    assert_equal "7.4", ScheduleEntry.find(10).act_number
    assert_equal 17, ScheduleEntry.find(20).act_number
    assert_equal 28, ScheduleEntry.find(31).act_number
    assert_equal "14:30", ScheduleEntry.find(30).start_time
    assert_equal ["Domingo 15", "Lunes 16"], entries.map(&:day).uniq
  end

  test "question data references only the numbered act on its source row" do
    schedule = YAML.safe_load_file(Rails.root.join("config/data/schedule.yml"))
    source = YAML.safe_load_file(Rails.root.join("config/data/questions.yml"))
    question_entries = source.fetch("schedule_entries")

    assert_equal schedule.map { |entry| entry.fetch("id") }, question_entries.map { |entry| entry.fetch("id") }
    assert_equal 12, question_entries.sum { |entry| entry.fetch("questions").size }
    assert_empty source.fetch("general_questions")
    assert_empty source.fetch("cross_cutting_questions")
    question_entries.zip(schedule).each do |entry, act|
      assert_equal act.fetch("activity"), entry.fetch("act")
      assert_equal [act.fetch("source_row")], entry.fetch("source_rows")
    end
    assert_equal 4, question_entries.find { |entry| entry.fetch("id") == 1 }.fetch("questions").size
    assert_equal 1, question_entries.find { |entry| entry.fetch("id") == 3 }.fetch("questions").size
    assert_empty question_entries.find { |entry| entry.fetch("id") == 2 }.fetch("questions")
  end

  test "counts resources for the requested activities" do
    Question.create!(schedule_entry_id: 1, body: "Pendiente")
    Question.create!(schedule_entry_id: 1, body: "Contestada", answer: "Listo")
    blank = Question.create!(schedule_entry_id: 1, body: "Sin contenido")
    blank.update_column(:answer, " \n ")
    Question.create!(schedule_entry_id: 3, body: "Otra actividad", answer: "Listo")
    File.open(Rails.root.join("test/fixtures/files/agenda.txt")) do |file|
      Document.create!(schedule_entry_id: 1, file: { io: file, filename: "agenda.txt", content_type: "text/plain" })
    end

    entries = [ScheduleEntry.find(1), ScheduleEntry.find(2)]
    counts = ScheduleEntry.resource_counts_for(entries)

    assert_equal({ questions: 3, answered: 1, documents: 1 }, counts.fetch(1))
    assert_equal({ questions: 0, answered: 0, documents: 0 }, counts.fetch(2))
    assert_equal [1, 2], counts.keys
    assert_equal counts, ScheduleEntry::ResourceCounts.for_entries(entries)
    assert_equal({}, ScheduleEntry.resource_counts_for([]))
    assert_equal({}, ScheduleEntry::ResourceCounts.for_entries([]))
  end
end

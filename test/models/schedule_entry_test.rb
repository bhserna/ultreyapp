require "test_helper"

class ScheduleEntryTest < ActiveSupport::TestCase
  test "keeps activity IDs and assigns the 27 official acts" do
    entries = ScheduleEntry.all
    acts = entries.map(&:act_number).compact

    assert_equal (1..49).to_a, entries.map(&:id).sort
    assert_equal (1..27).to_a, acts.uniq
    assert_nil ScheduleEntry.find(3).act_number
    assert_equal 3, ScheduleEntry.find(10).act_number
    assert_equal 3, ScheduleEntry.find(11).act_number
    assert_equal 17, ScheduleEntry.find(33).act_number
    assert_equal 25, ScheduleEntry.find(47).act_number
    assert_equal 27, ScheduleEntry.find(48).act_number
    assert_nil ScheduleEntry.find(49).act_number
    assert_equal "14:30", ScheduleEntry.find(48).start_time
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

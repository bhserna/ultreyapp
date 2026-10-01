require "test_helper"

class ScheduleEntryTest < ActiveSupport::TestCase
  test "counts resources for the requested activities" do
    Question.create!(schedule_entry_id: 1, body: "Pendiente")
    Question.create!(schedule_entry_id: 1, body: "Contestada", answer: "Listo")
    Question.create!(schedule_entry_id: 1, body: "Sin contenido", answer: " \n ")
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

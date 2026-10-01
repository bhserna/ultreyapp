class ScheduleEntry::ResourceCounts
  def self.for_entries(entries)
    new(entries).calculate
  end

  def initialize(entries)
    @counts = entries.to_h do |entry|
      [ entry.id, { questions: 0, answered: 0, documents: 0 } ]
    end
  end

  def calculate
    return @counts if @counts.empty?

    count_questions
    count_documents
    @counts
  end

  private

  def count_questions
    Question.where(schedule_entry_id: @counts.keys).pluck(:schedule_entry_id, :answer).each do |entry_id, answer|
      @counts[entry_id][:questions] += 1
      @counts[entry_id][:answered] += 1 if answer.present?
    end
  end

  def count_documents
    Document.where(schedule_entry_id: @counts.keys).group(:schedule_entry_id).count.each do |entry_id, total|
      @counts[entry_id][:documents] = total
    end
  end
end

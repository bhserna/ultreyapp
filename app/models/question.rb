class Question < ApplicationRecord
  belongs_to :topic, optional: true

  normalizes :answer, with: ->(answer) { answer.presence }

  validates :body, presence: true

  def schedule_entry
    ScheduleEntry.find(schedule_entry_id) if schedule_entry_id.present?
  end
end

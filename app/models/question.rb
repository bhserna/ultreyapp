class Question < ApplicationRecord
  belongs_to :topic, optional: true

  normalizes :answer, with: ->(answer) { answer.presence }

  validates :body, presence: true

  def activity
    Activity.find(schedule_entry_id, kind: "act") if schedule_entry_id.present?
  end
end

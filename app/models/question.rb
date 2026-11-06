class Question < ApplicationRecord
  belongs_to :topic, optional: true

  normalizes :answer, with: ->(answer) { answer.presence }

  validates :body, presence: true

  def activity
    Activity.acts.find(act_id) if act_id.present?
  end
end

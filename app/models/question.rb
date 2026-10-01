class Question < ApplicationRecord
  validates :schedule_entry_id, presence: true
  validates :body, presence: true
end

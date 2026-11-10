class ActivityDetail < ApplicationRecord
  self.ignored_columns += %w[commission]

  belongs_to :activity, inverse_of: :activity_detail

  validates :activity_id, uniqueness: true
end

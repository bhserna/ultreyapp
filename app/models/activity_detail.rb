class ActivityDetail < ApplicationRecord
  belongs_to :activity, inverse_of: :activity_detail

  validates :activity_id, uniqueness: true
end

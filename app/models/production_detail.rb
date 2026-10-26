class ProductionDetail < ApplicationRecord
  validates :schedule_entry_id, presence: true, uniqueness: true
end

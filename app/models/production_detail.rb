class ProductionDetail < ApplicationRecord
  validates :act_id, presence: true, uniqueness: true
end

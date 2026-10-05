class Topic < ApplicationRecord
  has_many :questions, dependent: :nullify
end

class Preparation < ApplicationRecord
  has_many :actions, -> { preparation_actions.order(:position) }, class_name: "Activity", inverse_of: :preparation, dependent: :restrict_with_error

  validates :title, :day, presence: true
  validates :phase, inclusion: { in: Schedule::PHASES.keys }
  validate :act_ids_reference_acts

  def start_time
    actions.first&.start_time.presence || self[:start_time]
  end

  def commissions
    actions.flat_map(&:commissions).uniq
  end

  private

  def act_ids_reference_acts
    if act_ids.is_a?(Array) && act_ids.all? { |id| id.is_a?(Integer) && id.positive? }
      return if (act_ids - Activity.acts.where(id: act_ids).pluck(:id)).empty?
    end

    errors.add(:act_ids, :invalid)
  end
end

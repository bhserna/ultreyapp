class Activity < ApplicationRecord
  belongs_to :preparation, optional: true, inverse_of: :actions
  has_one :activity_detail, dependent: :destroy, inverse_of: :activity

  scope :acts, -> { where(kind: "act").order(:id) }
  scope :operations, -> { where(kind: "operation").order(:id) }
  scope :preparation_actions, -> { where(kind: "preparation_action") }

  validates :title, :day, :source_id, presence: true
  validates :kind, inclusion: { in: %w[act operation preparation_action] }
  validates :phase, inclusion: { in: Schedule::PHASES.keys }
  validates :source_id, uniqueness: { scope: :kind }
  validates :preparation, presence: true, if: -> { kind == "preparation_action" }
  validates :preparation_id, :position, numericality: { only_integer: true, greater_than: 0 }, if: -> { kind == "preparation_action" }
  validates :position, uniqueness: { scope: :preparation_id }, if: -> { kind == "preparation_action" }
  validates :preparation_id, :position, absence: true, unless: -> { kind == "preparation_action" }

  def self.find_operation_by_source_id(source_id)
    operations.find_by!(source_id: source_id)
  end

  def executors
    detail_attributes.to_h["executors"]
  end

  def notes
    detail_attributes.to_h["notes"]
  end

  def pending_confirmations
    detail_attributes.to_h["pending_confirmations"]
  end

  def production_detail
    return unless detail_attributes

    attributes = ProductionInformation.members.index_with { |attribute| detail_attributes[attribute.to_s] }
    ProductionInformation.new(**attributes)
  end

  private

  def detail_attributes
    return @detail_attributes if defined?(@detail_attributes)

    @detail_attributes = if kind == "act"
      ProductionDetail.find_by(act_id: id)&.attributes
    else
      details
    end
  end
end

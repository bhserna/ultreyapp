class Activity < ApplicationRecord
  scope :acts, -> { where(kind: "act").order(:id) }
  scope :operations, -> { where(kind: "operation").order(:id) }

  validates :title, :day, :source_id, presence: true
  validates :kind, inclusion: { in: %w[act operation] }
  validates :phase, inclusion: { in: Schedule::PHASES.keys }
  validates :source_id, uniqueness: { scope: :kind }

  def self.import_from_source!
    acts = YAML.safe_load_file(Rails.root.join("config/data/schedule.yml")).map do |attributes|
      attributes.except("activity").merge(
        "title" => attributes.fetch("activity"), "kind" => "act", "source_id" => attributes.fetch("id")
      )
    end
    operations = YAML.safe_load_file(Rails.root.join("config/data/operational_activities.yml")).fetch("operational_activities").map do |attributes|
      attributes.merge("kind" => "operation")
    end
    source = acts + operations
    raise ArgumentError, "Activity source IDs must be unique" unless source.map { |attributes| attributes.fetch("id") }.uniq.size == source.size

    transaction do
      source.each do |attributes|
        find_or_create_by!(id: attributes.fetch("id")) do |activity|
          activity.assign_attributes(attributes)
        end
      end
    end
  end

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
      ProductionDetail.find_by(schedule_entry_id: id)&.attributes
    else
      details
    end
  end
end

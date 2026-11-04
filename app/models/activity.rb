class Activity
  ATTRIBUTES = %w[id day start_time end_time duration title commissions].freeze

  attr_reader(*ATTRIBUTES, :phase, :kind, :act_number, :category, :details, :source_id)

  def self.all
    acts + operations
  end

  def self.acts
    YAML.safe_load_file(Rails.root.join("config/data/schedule.yml")).map do |attributes|
      new(attributes.merge("title" => attributes.fetch("activity"), "kind" => "act"))
    end
  end

  def self.operations
    YAML.safe_load_file(Rails.root.join("config/data/operational_activities.yml")).fetch("operational_activities").map do |attributes|
      new(attributes.merge("kind" => "operation"))
    end
  end

  def self.find(id, kind: nil)
    all.find { |activity| activity.id.to_s == id.to_s && (kind.nil? || activity.kind == kind) } ||
      raise(ActiveRecord::RecordNotFound, "Activity not found")
  end

  def self.find_operation_by_source_id(source_id)
    operations.find { |activity| activity.source_id.to_s == source_id.to_s } ||
      raise(ActiveRecord::RecordNotFound, "Operation not found")
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

  def initialize(attributes)
    @kind = attributes.fetch("kind", "act")
    @phase = attributes.fetch("phase", "program")
    @act_number = attributes["act_number"]
    @category = attributes["category"]
    @details = attributes.fetch("details", {})
    @source_id = attributes.fetch("source_id", attributes.fetch("id"))
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
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

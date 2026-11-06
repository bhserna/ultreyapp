class Preparation
  ATTRIBUTES = %w[id title day schedule_entry_ids].freeze

  attr_reader(*ATTRIBUTES, :phase)

  def self.all
    YAML.safe_load_file(Rails.root.join("config/data/preparations.yml")).fetch("preparations").map do |attributes|
      new(attributes)
    end
  end

  def self.find(id)
    all.find { |preparation| preparation.id.to_s == id.to_s } || raise(ActiveRecord::RecordNotFound, "Preparation not found")
  end

  def actions
    @actions ||= Activity.preparation_actions.where(preparation_id: id).order(:position).to_a
  end

  def start_time
    actions.first&.start_time.presence || @start_time
  end

  def commissions
    actions.flat_map(&:commissions).uniq
  end

  def initialize(attributes)
    @phase = attributes.fetch("phase", "program")
    @start_time = attributes.fetch("start_time")
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
  end
end

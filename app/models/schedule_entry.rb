class ScheduleEntry
  ATTRIBUTES = %w[id act_number day start_time end_time duration activity commissions].freeze

  attr_reader(*ATTRIBUTES, :phase)

  def self.all
    YAML.safe_load_file(Rails.root.join("config/data/schedule.yml")).map { |attributes| new(attributes) }
  end

  def self.find(id)
    all.find { |entry| entry.id.to_s == id.to_s } || raise(ActiveRecord::RecordNotFound, "Schedule entry not found")
  end

  def initialize(attributes)
    @phase = attributes.fetch("phase", "program")
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
  end
end

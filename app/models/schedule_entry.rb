class ScheduleEntry
  ATTRIBUTES = %w[id day start_time end_time duration activity commissions].freeze

  attr_reader(*ATTRIBUTES)

  def self.all
    YAML.safe_load_file(Rails.root.join("config/schedule.yml")).map { |attributes| new(attributes) }
  end

  def self.find(id)
    all.find { |entry| entry.id.to_s == id.to_s } || raise(ActiveRecord::RecordNotFound, "Schedule entry not found")
  end

  def initialize(attributes)
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
  end
end

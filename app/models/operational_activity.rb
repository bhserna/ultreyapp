class OperationalActivity
  ATTRIBUTES = %w[id title category day start_time end_time duration commissions details].freeze

  attr_reader(*ATTRIBUTES)

  def self.all
    YAML.safe_load_file(Rails.root.join("config/data/operational_activities.yml")).fetch("operational_activities").map do |attributes|
      new(attributes)
    end
  end

  def self.find(id)
    all.find { |activity| activity.id.to_s == id.to_s } || raise(ActiveRecord::RecordNotFound, "Operational activity not found")
  end

  def initialize(attributes)
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
  end
end

class Activity
  ATTRIBUTES = %w[id act_number day start_time end_time duration title commissions].freeze

  attr_reader(*ATTRIBUTES, :phase, :kind)

  def self.all
    YAML.safe_load_file(Rails.root.join("config/data/schedule.yml")).map do |attributes|
      new(attributes.merge("title" => attributes.fetch("activity")))
    end
  end

  def self.find(id)
    all.find { |entry| entry.id.to_s == id.to_s } || raise(ActiveRecord::RecordNotFound, "Activity not found")
  end

  def initialize(attributes)
    @kind = attributes.fetch("kind", "act")
    @phase = attributes.fetch("phase", "program")
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
  end
end

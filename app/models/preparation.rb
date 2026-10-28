class Preparation
  ATTRIBUTES = %w[id title day start_time schedule_entry_ids actions].freeze

  attr_reader(*ATTRIBUTES, :phase)

  def self.all
    YAML.safe_load_file(Rails.root.join("config/data/preparations.yml")).fetch("preparations").map do |attributes|
      new(attributes)
    end
  end

  def self.find(id)
    all.find { |preparation| preparation.id.to_s == id.to_s } || raise(ActiveRecord::RecordNotFound, "Preparation not found")
  end

  def commissions
    actions.filter_map do |action|
      commission = action.fetch("commission")
      commission if commission.present? && !commission.include?("?")
    end.uniq
  end

  def initialize(attributes)
    @phase = attributes.fetch("phase", "program")
    ATTRIBUTES.each { |attribute| instance_variable_set("@#{attribute}", attributes.fetch(attribute)) }
  end
end

class Schedule
  ROW_TYPES = %w[acts preparations operations].freeze
  PHASES = {
    "pre_event" => "Operación previa",
    "before_parade" => "Preparación previa al desfile",
    "program" => "Programa del día"
  }.freeze

  def initialize(day:, commission:, row_type: nil)
    @day = day
    @commission = commission
    @row_type = row_type
  end

  def days
    (all_operations + all_acts + all_preparations).map(&:day).uniq
  end

  def commissions
    all_rows.flat_map(&:commissions).uniq.sort
  end

  def selected_day
    days.include?(@day) ? @day : all_acts.first.day
  end

  def selected_commission
    @commission if commissions.include?(@commission)
  end

  def selected_row_type
    @row_type if ROW_TYPES.include?(@row_type)
  end

  def entries
    all_acts.select { |activity| matches_filters?(activity) }
  end

  def rows
    candidates = case selected_row_type
    when "acts" then all_acts
    when "preparations" then all_preparations
    when "operations" then all_operations
    else all_rows
    end

    candidates.select { |activity| matches_filters?(activity) }.sort_by do |activity|
      time = activity.start_time.to_s
      if !time.match?(/\A\d{2}:\d{2}\z/) && activity.respond_to?(:end_time)
        time = activity.end_time.to_s
      end
      [ PHASES.keys.index(activity.phase), time.match?(/\A\d{2}:\d{2}\z/) ? time : "24:00" ]
    end
  end

  private
    def matches_filters?(activity)
      activity.day == selected_day && (selected_commission.nil? || activity.commissions.include?(selected_commission))
    end

    def all_rows
      all_operations + all_preparations + all_acts
    end

    def all_operations
      @all_operations ||= all_activities.select { |activity| activity.kind == "operation" }
    end

    def all_preparations
      @all_preparations ||= Preparation.order(:id).preload(:actions).to_a
    end

    def all_acts
      @all_acts ||= all_activities.select { |activity| activity.kind == "act" }
    end

    def all_activities
      @all_activities ||= Activity.order(:id).to_a
    end
end

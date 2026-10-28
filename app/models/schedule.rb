class Schedule
  ROW_TYPES = %w[acts preparations operations].freeze

  def initialize(day:, commission:, row_type: nil)
    @day = day
    @commission = commission
    @row_type = row_type
  end

  def days
    (all_operations + all_entries + all_preparations).map(&:day).uniq
  end

  def commissions
    all_rows.flat_map(&:commissions).uniq.sort
  end

  def selected_day
    days.include?(@day) ? @day : all_entries.first.day
  end

  def selected_commission
    @commission if commissions.include?(@commission)
  end

  def selected_row_type
    @row_type if ROW_TYPES.include?(@row_type)
  end

  def entries
    all_entries.select { |entry| matches_filters?(entry) }
  end

  def rows
    candidates = case selected_row_type
    when "acts" then all_entries
    when "preparations" then all_preparations
    when "operations" then all_operations
    else all_rows
    end

    candidates.select { |entry| matches_filters?(entry) }.sort_by do |entry|
      time = entry.start_time.to_s
      time.match?(/\A\d{2}:\d{2}\z/) ? time : "24:00"
    end
  end

  private
    def matches_filters?(entry)
      entry.day == selected_day && (selected_commission.nil? || entry.commissions.include?(selected_commission))
    end

    def all_rows
      all_operations + all_preparations + all_entries
    end

    def all_operations
      @all_operations ||= OperationalActivity.all
    end

    def all_preparations
      @all_preparations ||= Preparation.all
    end

    def all_entries
      @all_entries ||= ScheduleEntry.all
    end
end

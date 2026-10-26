class Schedule
  def initialize(day:, commission:)
    @day = day
    @commission = commission
  end

  def days
    all_entries.map(&:day).uniq
  end

  def commissions
    (all_entries + all_preparations).flat_map(&:commissions).uniq.sort
  end

  def selected_day
    days.include?(@day) ? @day : days.first
  end

  def selected_commission
    @commission if commissions.include?(@commission)
  end

  def entries
    @entries ||= all_entries.select do |entry|
      entry.day == selected_day && (selected_commission.nil? || entry.commissions.include?(selected_commission))
    end
  end

  def rows
    preparations = all_preparations.select do |preparation|
      preparation.day == selected_day && (selected_commission.nil? || preparation.commissions.include?(selected_commission))
    end

    (preparations + entries).sort_by do |entry|
      time = entry.start_time.to_s
      time.match?(/\A\d{2}:\d{2}\z/) ? time : "24:00"
    end
  end

  private
    def all_preparations
      @all_preparations ||= Preparation.all
    end

    def all_entries
      @all_entries ||= ScheduleEntry.all
    end
end

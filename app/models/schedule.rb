class Schedule
  def initialize(day:, commission:)
    @day = day
    @commission = commission
  end

  def days
    all_entries.map(&:day).uniq
  end

  def commissions
    all_entries.flat_map(&:commissions).uniq.sort
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

  def resource_counts
    @resource_counts ||= ScheduleEntry.resource_counts_for(entries)
  end

  private
    def all_entries
      @all_entries ||= ScheduleEntry.all
    end
end

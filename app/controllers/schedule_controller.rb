class ScheduleController < ApplicationController
  def index
    entries = ScheduleEntry.all
    @days = entries.map(&:day).uniq
    @commissions = entries.flat_map(&:commissions).uniq.sort
    @selected_day = @days.include?(params[:day]) ? params[:day] : @days.first
    @selected_commission = params[:commission] if @commissions.include?(params[:commission])
    @schedule_entries = entries.select do |entry|
      entry.day == @selected_day && (@selected_commission.nil? || entry.commissions.include?(@selected_commission))
    end

    @resource_counts = ScheduleEntry.resource_counts_for(@schedule_entries)
  end
end

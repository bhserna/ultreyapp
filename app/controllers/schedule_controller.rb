class ScheduleController < ApplicationController
  def index
    entries = ScheduleEntry.all
    @days = entries.map(&:day).uniq
    @selected_day = @days.include?(params[:day]) ? params[:day] : @days.first
    @schedule_entries = entries.select { |entry| entry.day == @selected_day }
  end
end

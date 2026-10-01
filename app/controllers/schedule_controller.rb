class ScheduleController < ApplicationController
  def index
    entries = YAML.safe_load_file(Rails.root.join("config/schedule.yml"))
    @days = entries.map { |entry| entry.fetch("day") }.uniq
    @selected_day = @days.include?(params[:day]) ? params[:day] : @days.first
    @schedule_entries = entries.select { |entry| entry.fetch("day") == @selected_day }
  end
end

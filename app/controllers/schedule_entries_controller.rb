class ScheduleEntriesController < ApplicationController
  def show
    @schedule_entry = ScheduleEntry.find(params[:id])
  end
end

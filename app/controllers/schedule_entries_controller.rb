class ScheduleEntriesController < ApplicationController
  def show
    @schedule_entry = ScheduleEntry.find(params[:id])
    @production_detail = ProductionDetail.find_by(schedule_entry_id: @schedule_entry.id)
  end
end

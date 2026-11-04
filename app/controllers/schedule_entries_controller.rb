class ScheduleEntriesController < ApplicationController
  def show
    @activity = Activity.find(params[:id], kind: "act")
    @production_detail = ProductionDetail.find_by(schedule_entry_id: @activity.id)
  end
end

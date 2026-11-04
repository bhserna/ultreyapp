class ScheduleEntriesController < ApplicationController
  def show
    @activity = Activity.find(params[:id], kind: "act")
  end
end

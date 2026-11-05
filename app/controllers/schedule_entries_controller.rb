class ScheduleEntriesController < ApplicationController
  def show
    @activity = Activity.acts.find(params[:id])
  end
end

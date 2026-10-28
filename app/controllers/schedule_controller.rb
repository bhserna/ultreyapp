class ScheduleController < ApplicationController
  def index
    @schedule = Schedule.new(day: params[:day], commission: params[:commission], row_type: params[:row_type])
  end
end

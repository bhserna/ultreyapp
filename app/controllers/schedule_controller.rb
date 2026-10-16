class ScheduleController < ApplicationController
  def index
    @schedule = Schedule.new(day: params[:day], commission: params[:commission])
  end
end

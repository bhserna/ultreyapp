class PreparationsController < ApplicationController
  before_action :set_preparation

  def show
    @schedule_entries = @preparation.schedule_entry_ids.map { |id| ScheduleEntry.find(id) }
  end

  private

  def set_preparation
    @preparation = Preparation.find(params[:id])
  end
end

class PreparationsController < ApplicationController
  before_action :set_preparation

  def show
    @activities = @preparation.schedule_entry_ids.map { |id| Activity.acts.find(id) }
  end

  private

  def set_preparation
    @preparation = Preparation.find(params[:id])
  end
end

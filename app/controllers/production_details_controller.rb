class ProductionDetailsController < ApplicationController
  before_action :set_activity

  def new
    redirect_to new_activity_activity_detail_path(@activity)
  end

  def edit
    redirect_to edit_activity_activity_detail_path(@activity)
  end

  private

  def set_activity
    @activity = Activity.acts.find(params[:schedule_entry_id])
  end
end

class OperationalActivitiesController < ApplicationController
  def show
    @activity = Activity.find_operation_by_source_id(params[:id])
  end
end

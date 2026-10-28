class OperationalActivitiesController < ApplicationController
  def show
    @operational_activity = OperationalActivity.find(params[:id])
  end
end

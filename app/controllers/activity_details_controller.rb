class ActivityDetailsController < ApplicationController
  before_action :set_activity
  before_action :set_activity_detail, only: %i[edit update]

  def new
    if @activity.activity_detail
      redirect_to edit_activity_activity_detail_path(@activity)
    else
      @activity_detail = ActivityDetail.new(activity: @activity)
    end
  end

  def create
    @activity_detail = ActivityDetail.new(activity_detail_params)
    @activity_detail.activity = @activity

    if @activity_detail.save
      redirect_to helpers.activity_return_path(@activity), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @activity_detail.update(activity_detail_params)
      redirect_to helpers.activity_return_path(@activity), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_activity
    @activity = Activity.find(params[:activity_id])
  end

  def set_activity_detail
    @activity_detail = @activity.activity_detail || raise(ActiveRecord::RecordNotFound)
  end

  def activity_detail_params
    params.expect(activity_detail: %i[
      description executors screen audio room_lighting stage_lighting aisle_lighting
      requirements notes radios media_files pending_confirmations commission
      arena_questions general_questions
    ])
  end
end

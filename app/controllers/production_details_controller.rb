class ProductionDetailsController < ApplicationController
  before_action :set_schedule_entry
  before_action :set_production_detail, only: %i[edit update destroy]

  def new
    @production_detail = ProductionDetail.new(schedule_entry_id: @schedule_entry.id)
  end

  def create
    @production_detail = ProductionDetail.new(production_detail_params)
    @production_detail.schedule_entry_id = @schedule_entry.id

    if @production_detail.save
      redirect_to schedule_entry_path(@schedule_entry.id), status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @production_detail.update(production_detail_params)
      redirect_to schedule_entry_path(@schedule_entry.id), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @production_detail.destroy!
    redirect_to schedule_entry_path(@schedule_entry.id), status: :see_other
  end

  private

  def set_schedule_entry
    @schedule_entry = ScheduleEntry.find(params[:schedule_entry_id])
  end

  def set_production_detail
    @production_detail = ProductionDetail.find_by!(schedule_entry_id: @schedule_entry.id)
  end

  def production_detail_params
    params.expect(production_detail: %i[executors screen audio room_lighting stage_lighting aisle_lighting requirements notes radios pending_confirmations])
  end
end

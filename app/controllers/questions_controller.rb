class QuestionsController < ApplicationController
  before_action :set_schedule_entry
  before_action :set_question, only: %i[edit update destroy]

  def index
    @questions = questions_for_entry
    @question = Question.new
  end

  def create
    @question = Question.new(question_params.merge(schedule_entry_id: @schedule_entry.id))
    @question.save!
    redirect_to schedule_entry_questions_path(@schedule_entry.id), status: :see_other
  end

  def edit
  end

  def update
    @question.update!(question_params)
    redirect_to schedule_entry_questions_path(@schedule_entry.id), status: :see_other
  end

  def destroy
    @question.destroy!
    redirect_to schedule_entry_questions_path(@schedule_entry.id), status: :see_other
  end

  private

  def set_schedule_entry
    @schedule_entry = ScheduleEntry.find(params[:schedule_entry_id])
  end

  def set_question
    @question = questions_for_entry.find(params[:id])
  end

  def questions_for_entry
    Question.where(schedule_entry_id: @schedule_entry.id).order(:created_at, :id)
  end

  def question_params
    params.require(:question).permit(:body)
  end
end

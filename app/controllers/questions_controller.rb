class QuestionsController < ApplicationController
  before_action :maybe_set_schedule_entry, only: %i[index create]
  before_action :set_question, only: %i[edit update destroy]

  def index
    @questions = fetch_questions
    @question = Question.new
  end

  def create
    @question = Question.new(question_params.merge(schedule_entry_id: @schedule_entry&.id))
    @question.save!
    redirect_to helpers.questions_path_maybe_for(@schedule_entry), status: :see_other
  end

  def edit
  end

  def update
    @question.update!(question_params)
    redirect_to helpers.questions_path_maybe_for(@schedule_entry), status: :see_other
  end

  def destroy
    @question.destroy!
    redirect_to helpers.questions_path_maybe_for(@schedule_entry), status: :see_other
  end

  private

  def maybe_set_schedule_entry
    @schedule_entry = ScheduleEntry.find(params[:schedule_entry_id]) if params[:schedule_entry_id].present?
  end

  def set_question
    @question = Question.find(params[:id])
    @schedule_entry = @question.schedule_entry
  end

  def fetch_questions
    Question.where(schedule_entry_id: @schedule_entry&.id).order(:created_at, :id)
  end

  def question_params
    params.require(:question).permit(:body)
  end
end

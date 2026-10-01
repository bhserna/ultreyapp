class AnswersController < ApplicationController
  before_action :set_question

  def edit
  end

  def update
    @question.update!(answer_params)
    redirect_to schedule_entry_questions_path(@schedule_entry.id), status: :see_other
  end

  private

  def set_question
    @schedule_entry = ScheduleEntry.find(params[:schedule_entry_id])
    @question = Question.where(schedule_entry_id: @schedule_entry.id).find(params[:question_id])
  end

  def answer_params
    params.require(:question).permit(:answer)
  end
end

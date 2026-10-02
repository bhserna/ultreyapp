class AnswersController < ApplicationController
  before_action :set_question

  def edit
  end

  def update
    @question.update!(answer_params)
    redirect_to helpers.questions_path_maybe_for(@schedule_entry), status: :see_other
  end

  private

  def set_question
    @question = Question.find(params[:question_id])
    @schedule_entry = @question.schedule_entry
  end

  def answer_params
    params.require(:question).permit(:answer)
  end
end

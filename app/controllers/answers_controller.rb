class AnswersController < ApplicationController
  before_action :set_question

  def edit
  end

  def update
    @question.update!(answer_params)
    redirect_to helpers.questions_collection_path(activity: @activity, topic: @question.topic), status: :see_other
  end

  private

  def set_question
    @question = Question.find(params[:question_id])
    @activity = @question.activity
  end

  def answer_params
    params.require(:question).permit(:answer)
  end
end

class QuestionsController < ApplicationController
  before_action :maybe_set_schedule_entry, only: %i[index create]
  before_action :maybe_set_topics, only: %i[index create]
  before_action :set_question, only: %i[edit update destroy]

  def index
    @questions = fetch_questions
    @question = Question.new
  end

  def create
    Question.create!(question_params.merge(schedule_entry_id: @schedule_entry&.id, topic: @topic))
    redirect_to helpers.questions_collection_path(schedule_entry: @schedule_entry, topic: @topic), status: :see_other
  end

  def edit
  end

  def update
    @question.update!(question_params)
    redirect_to helpers.questions_collection_path(schedule_entry: @schedule_entry, topic: @question.topic), status: :see_other
  end

  def destroy
    topic = @question.topic
    @question.destroy!
    redirect_to helpers.questions_collection_path(schedule_entry: @schedule_entry, topic: topic), status: :see_other
  end

  private

  def maybe_set_schedule_entry
    @schedule_entry = ScheduleEntry.find(params[:schedule_entry_id]) if params[:schedule_entry_id].present?
  end

  def maybe_set_topics
    return if @schedule_entry

    @topics = Topic.order(:name, :id)
    @topic = Topic.find(params[:topic_id]) if params[:topic_id].present?
  end

  def set_question
    @question = Question.find(params[:id])
    @schedule_entry = @question.schedule_entry
  end

  def fetch_questions
    questions = Question.where(schedule_entry_id: @schedule_entry&.id)
    questions = questions.where(topic: @topic) if @schedule_entry.nil?
    questions.order(:created_at, :id)
  end

  def question_params
    params.require(:question).permit(:body)
  end
end

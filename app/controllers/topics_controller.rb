class TopicsController < ApplicationController
  before_action :set_topic, only: %i[edit update destroy]

  def index
    @topics = Topic.order(:name, :id)
    @topic = Topic.new
  end

  def create
    Topic.create!(topic_params)
    redirect_to topics_path, status: :see_other
  end

  def edit
  end

  def update
    @topic.update!(topic_params)
    redirect_to topics_path, status: :see_other
  end

  def destroy
    @topic.destroy!
    redirect_to topics_path, status: :see_other
  end

  private

  def set_topic
    @topic = Topic.find(params[:id])
  end

  def topic_params
    params.require(:topic).permit(:name)
  end
end

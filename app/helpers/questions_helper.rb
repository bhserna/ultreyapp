module QuestionsHelper
  def questions_collection_path(activity:, topic:)
    activity ? schedule_entry_questions_path(activity.id) : questions_path(topic_id: topic&.id)
  end
end

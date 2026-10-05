module QuestionsHelper
  def questions_collection_path(schedule_entry:, topic:)
    schedule_entry ? schedule_entry_questions_path(schedule_entry.id) : questions_path(topic_id: topic&.id)
  end
end

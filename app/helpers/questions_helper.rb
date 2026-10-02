module QuestionsHelper
  def questions_path_maybe_for(schedule_entry)
    schedule_entry ? schedule_entry_questions_path(schedule_entry.id) : questions_path
  end
end

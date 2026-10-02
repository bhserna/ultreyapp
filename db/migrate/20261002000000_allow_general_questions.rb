class AllowGeneralQuestions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :questions, :schedule_entry_id, true
  end
end

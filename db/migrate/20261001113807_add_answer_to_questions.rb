class AddAnswerToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :answer, :text
  end
end

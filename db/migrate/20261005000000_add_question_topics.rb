class AddQuestionTopics < ActiveRecord::Migration[8.1]
  def change
    unless table_exists?(:topics)
      create_table :topics do |t|
        t.string :name, null: false

        t.timestamps
      end
    end

    add_reference :questions, :topic, foreign_key: true unless column_exists?(:questions, :topic_id)
  end
end

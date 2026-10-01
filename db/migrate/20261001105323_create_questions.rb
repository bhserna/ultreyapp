class CreateQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :questions do |t|
      t.integer :schedule_entry_id, null: false
      t.text :body, null: false

      t.timestamps
    end

    add_index :questions, :schedule_entry_id
  end
end

class CreateActivityDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_details do |t|
      t.references :activity, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.text :description
      t.text :executors
      t.text :notes
      t.text :pending_confirmations
      t.text :screen
      t.text :audio
      t.text :room_lighting
      t.text :stage_lighting
      t.text :aisle_lighting
      t.text :requirements
      t.text :radios
      t.text :media_files
      t.text :commission
      t.text :arena_questions
      t.text :general_questions

      t.timestamps
    end
  end
end

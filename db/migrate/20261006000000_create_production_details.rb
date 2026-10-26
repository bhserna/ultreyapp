class CreateProductionDetails < ActiveRecord::Migration[8.1]
  def change
    create_table :production_details do |t|
      t.integer :schedule_entry_id, null: false, index: { unique: true }
      t.text :executors
      t.text :screen
      t.text :audio
      t.text :room_lighting
      t.text :stage_lighting
      t.text :aisle_lighting
      t.text :requirements
      t.text :notes
      t.text :radios
      t.text :pending_confirmations

      t.timestamps
    end
  end
end

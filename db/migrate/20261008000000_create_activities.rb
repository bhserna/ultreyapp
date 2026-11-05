class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.string :kind, null: false
      t.string :title, null: false
      t.string :day, null: false
      t.string :phase, null: false, default: "program"
      t.string :start_time
      t.string :end_time
      t.string :duration
      t.json :act_number
      t.string :category
      t.json :commissions, null: false, default: []
      t.json :details, null: false, default: {}
      t.integer :source_id, null: false
      t.string :source_sheet
      t.integer :source_row
      t.timestamps
    end

    add_index :activities, [ :kind, :source_id ], unique: true
  end
end

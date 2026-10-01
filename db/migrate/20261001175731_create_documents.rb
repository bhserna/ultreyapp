class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.integer :schedule_entry_id, null: false

      t.timestamps
    end

    add_index :documents, :schedule_entry_id
  end
end

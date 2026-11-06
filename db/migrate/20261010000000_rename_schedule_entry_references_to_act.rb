class RenameScheduleEntryReferencesToAct < ActiveRecord::Migration[8.1]
  def change
    rename_column :questions, :schedule_entry_id, :act_id
    rename_column :documents, :schedule_entry_id, :act_id
    rename_column :production_details, :schedule_entry_id, :act_id
  end
end

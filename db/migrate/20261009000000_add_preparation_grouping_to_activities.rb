class AddPreparationGroupingToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :preparation_id, :integer
    add_column :activities, :position, :integer
    add_index :activities, [ :preparation_id, :position ], unique: true
  end
end

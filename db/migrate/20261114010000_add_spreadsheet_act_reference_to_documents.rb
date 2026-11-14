class AddSpreadsheetActReferenceToDocuments < ActiveRecord::Migration[8.1]
  def change
    change_column_null :documents, :act_id, true
    add_column :documents, :spreadsheet_act_key, :string
    add_column :documents, :spreadsheet_act_title, :string
    add_index :documents, :spreadsheet_act_key
    add_check_constraint :documents,
      "(act_id IS NOT NULL AND spreadsheet_act_key IS NULL) OR " \
      "(act_id IS NULL AND spreadsheet_act_key IS NOT NULL AND length(trim(spreadsheet_act_key)) > 0)",
      name: "documents_exactly_one_act_reference"
  end
end

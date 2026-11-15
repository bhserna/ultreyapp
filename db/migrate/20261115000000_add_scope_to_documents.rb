class AddScopeToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_column :documents, :scope, :string, null: false, default: "act"
    remove_check_constraint :documents,
      name: "documents_exactly_one_act_reference",
      expression: "(act_id IS NOT NULL AND spreadsheet_act_key IS NULL) OR " \
        "(act_id IS NULL AND spreadsheet_act_key IS NOT NULL AND length(trim(spreadsheet_act_key)) > 0)"
    add_check_constraint :documents,
      "(scope = 'general' AND act_id IS NULL AND spreadsheet_act_key IS NULL) OR " \
      "(scope = 'act' AND ((act_id IS NOT NULL AND spreadsheet_act_key IS NULL) OR " \
      "(act_id IS NULL AND spreadsheet_act_key IS NOT NULL AND length(trim(spreadsheet_act_key)) > 0)))",
      name: "documents_scope_matches_act_reference"
  end
end

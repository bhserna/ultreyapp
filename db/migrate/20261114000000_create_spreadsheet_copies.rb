class CreateSpreadsheetCopies < ActiveRecord::Migration[8.1]
  def change
    create_table :spreadsheet_copies do |t|
      t.timestamps
    end
  end
end

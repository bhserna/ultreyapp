require "json"
require "fileutils"
require "securerandom"

class RemoveRetiredProgram < ActiveRecord::Migration[8.1]
  RETIRED_TABLES = %w[activity_details activities preparations questions topics].freeze

  def up
    archive_retired_data

    remove_check_constraint :documents, name: "documents_scope_matches_act_reference"
    execute "UPDATE documents SET scope = 'general', act_id = NULL WHERE act_id IS NOT NULL"
    remove_column :documents, :act_id
    add_check_constraint :documents,
      "(scope = 'general' AND spreadsheet_act_key IS NULL) OR " \
        "(scope = 'act' AND spreadsheet_act_key IS NOT NULL AND length(trim(spreadsheet_act_key)) > 0)",
      name: "documents_scope_matches_act_reference"

    RETIRED_TABLES.each { |table| drop_table table }
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Restore a database backup to recover the retired program."
  end

  private

  def archive_directory
    Rails.root.join("storage", "retired_program_backups")
  end

  def archive_retired_data
    tables = RETIRED_TABLES.to_h do |table|
      [ table, connection.select_all("SELECT * FROM #{connection.quote_table_name(table)} ORDER BY id").to_a ]
    end
    tables["documents"] = connection.select_all("SELECT * FROM documents WHERE act_id IS NOT NULL ORDER BY id").to_a
    return if tables.values.all?(&:empty?)

    FileUtils.mkdir_p(archive_directory, mode: 0o700)
    path = File.join(archive_directory, "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}-#{SecureRandom.uuid}.json")
    archive = { "migration" => self.class.name, "exported_at" => Time.now.utc.iso8601, "tables" => tables }
    File.open(path, File::WRONLY | File::CREAT | File::EXCL, 0o600) do |file|
      file.write(JSON.pretty_generate(archive))
      file.flush
      file.fsync
    end
    say "Retired program data exported to #{path}. Keep this archive with the database and file backups."
  end
end

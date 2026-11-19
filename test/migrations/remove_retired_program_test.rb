require "test_helper"
require "tmpdir"
require Rails.root.join("db/migrate/20261115010000_remove_retired_program")

class RemoveRetiredProgramTest < ActiveSupport::TestCase
  setup do
    @archive_directory = Dir.mktmpdir("retired-program")
    RemoveRetiredProgram::RETIRED_TABLES.each do |name|
      connection.create_table(name) { |table| table.text :content }
    end
    connection.add_reference :activities, :preparation, foreign_key: true
    connection.add_reference :activity_details, :activity, foreign_key: { on_delete: :cascade }
    connection.add_reference :questions, :topic, foreign_key: true
    connection.add_column :documents, :act_id, :integer
    connection.add_index :documents, :act_id
    connection.remove_check_constraint :documents, name: "documents_scope_matches_act_reference"
    connection.add_check_constraint :documents,
      "(scope = 'general' AND act_id IS NULL AND spreadsheet_act_key IS NULL) OR " \
        "(scope = 'act' AND ((act_id IS NOT NULL AND spreadsheet_act_key IS NULL) OR " \
        "(act_id IS NULL AND spreadsheet_act_key IS NOT NULL AND length(trim(spreadsheet_act_key)) > 0)))",
      name: "documents_scope_matches_act_reference"
    Document.reset_column_information
  end

  teardown do
    FileUtils.remove_entry(@archive_directory)
    Document.reset_column_information
  end

  test "archive all retired rows before dropping their tables and preserve documents and files" do
    RemoveRetiredProgram::RETIRED_TABLES.each do |table|
      connection.execute("INSERT INTO #{connection.quote_table_name(table)} (id, content) VALUES (1, 'Contenido original')")
    end
    legacy = create_document(scope: "general")
    connection.execute("UPDATE documents SET scope = 'act', act_id = 1 WHERE id = #{legacy.id}")
    general = create_document(scope: "general")
    spreadsheet = create_document(spreadsheet_act_key: "act-001")
    original_files = [ legacy, general, spreadsheet ].to_h { |document| [ document.id, document.file.download ] }
    original_documents = [ general, spreadsheet ].to_h { |document| [ document.id, document.reload.attributes ] }
    original_attachments = ActiveStorage::Attachment.order(:id).map(&:attributes)
    original_blobs = ActiveStorage::Blob.order(:id).map(&:attributes)

    migrate

    archive_path = Dir[File.join(@archive_directory, "*.json")].sole
    archive = JSON.parse(File.read(archive_path))
    assert_equal "RemoveRetiredProgram", archive.fetch("migration")
    RemoveRetiredProgram::RETIRED_TABLES.each do |table|
      assert_not connection.table_exists?(table)
      assert_equal "Contenido original", archive.fetch("tables").fetch(table).sole.fetch("content")
    end
    archived_document = archive.fetch("tables").fetch("documents").sole
    assert_equal legacy.id, archived_document.fetch("id")
    assert_equal 1, archived_document.fetch("act_id")
    assert_equal 0o600, File.stat(archive_path).mode & 0o777
    assert_not connection.column_exists?(:documents, :act_id)
    Document.reset_column_information
    assert legacy.reload.scope_general?
    original_documents.each do |id, attributes|
      assert_equal attributes.except("act_id"), Document.find(id).attributes
    end
    original_files.each { |id, content| assert_equal content, Document.find(id).file.download }
    assert_equal original_attachments, ActiveStorage::Attachment.order(:id).map(&:attributes)
    assert_equal original_blobs, ActiveStorage::Blob.order(:id).map(&:attributes)
    assert_equal [ general.id, legacy.id ].sort, Document.scope_general.pluck(:id).sort
  end

  test "do not change the database if the archive cannot be written" do
    connection.execute("INSERT INTO questions (content) VALUES ('Preserve this question')")
    blocked_directory = File.join(@archive_directory, "not-a-directory")
    File.write(blocked_directory, "blocked")
    @archive_directory_override = blocked_directory

    assert_raises(Errno::EEXIST) { migrate }

    RemoveRetiredProgram::RETIRED_TABLES.each { |table| assert connection.table_exists?(table) }
    assert connection.column_exists?(:documents, :act_id)
    assert_equal "Preserve this question", connection.select_value("SELECT content FROM questions")
  end

  test "empty retired tables need no archive" do
    migrate

    assert_empty Dir.children(@archive_directory)
    RemoveRetiredProgram::RETIRED_TABLES.each { |table| assert_not connection.table_exists?(table) }
  end

  test "rollback requires a database backup" do
    migration = RemoveRetiredProgram.new
    assert_raises ActiveRecord::IrreversibleMigration do
      migration.suppress_messages { migration.migrate(:down) }
    end
  end

  private

  def connection
    ActiveRecord::Base.connection
  end

  def create_document(**attributes)
    Document.create!(**attributes, file: { io: StringIO.new("Original file"), filename: "instructions.txt" })
  end

  def migrate
    directory = @archive_directory_override || @archive_directory
    migration = RemoveRetiredProgram.new
    migration.define_singleton_method(:archive_directory) { directory }
    migration.suppress_messages { migration.migrate(:up) }
  end
end

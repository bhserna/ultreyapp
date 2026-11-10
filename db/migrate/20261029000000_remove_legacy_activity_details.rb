class RemoveLegacyActivityDetails < ActiveRecord::Migration[8.1]
  class ActivityRecord < ActiveRecord::Base
    self.table_name = "activities"
  end

  class ActivityDetailRecord < ActiveRecord::Base
    self.table_name = "activity_details"
  end

  class ProductionDetailRecord < ActiveRecord::Base
    self.table_name = "production_details"
  end

  DETAIL_FIELDS = %w[
    description executors notes pending_confirmations screen audio room_lighting
    stage_lighting aisle_lighting requirements radios media_files arena_questions
    general_questions
  ].freeze

  def up
    ActivityRecord.transaction do
      verify_sources!
      # Native DROP COLUMN avoids rebuilding activities and cascading deletion of its details in SQLite.
      execute "ALTER TABLE activities DROP COLUMN details"
      execute "ALTER TABLE activity_details DROP COLUMN commission"
      drop_table :production_details
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Legacy activity data must be recovered from a verified backup"
  end

  private

  def verify_sources!
    [ ActivityRecord, ActivityDetailRecord, ProductionDetailRecord ].each(&:reset_column_information)
    errors = []

    ActivityRecord.find_each do |activity|
      json = activity.details
      unless json.is_a?(Hash)
        errors << "Activity #{activity.id}: details must be an object"
        next
      end

      unknown = json.keys - DETAIL_FIELDS - [ "commission" ]
      errors << "Activity #{activity.id}: unpreserved JSON keys: #{unknown.join(', ')}" if unknown.any?
      json.each do |field, value|
        unless value.nil? || value.is_a?(String)
          errors << "Activity #{activity.id}: #{field} contains nontext source data"
        end
      end
      if json.slice(*DETAIL_FIELDS).values.any?(&:present?) && !ActivityDetailRecord.exists?(activity_id: activity.id)
        errors << "Activity #{activity.id}: migrated details are missing"
      end
    end

    ProductionDetailRecord.find_each do |production|
      unless ActivityRecord.exists?(id: production.act_id, kind: "act")
        errors << "ProductionDetail #{production.id}: invalid act reference #{production.act_id}"
      end
      content = production.attributes.except("id", "act_id", "created_at", "updated_at")
      unknown = content.keys - DETAIL_FIELDS
      errors << "ProductionDetail #{production.id}: unpreserved columns: #{unknown.join(', ')}" if unknown.any?
      if content.values.any?(&:present?) && !ActivityDetailRecord.exists?(activity_id: production.act_id)
        errors << "ProductionDetail #{production.id}: migrated details are missing"
      end
    end

    ActivityDetailRecord.where.not(commission: nil).find_each do |detail|
      errors << "Activity #{detail.activity_id}: commission text has not been reconciled" if detail.commission.present?
    end

    if errors.any?
      raise ActiveRecord::MigrationError, "Legacy activity cleanup aborted:\n#{errors.join("\n")}"
    end
  end
end

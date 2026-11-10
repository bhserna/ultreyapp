class BackfillActivityDetails < ActiveRecord::Migration[8.1]
  class ActivityRecord < ActiveRecord::Base
    self.table_name = "activities"
  end

  class ProductionDetailRecord < ActiveRecord::Base
    self.table_name = "production_details"
  end

  class ActivityDetailRecord < ActiveRecord::Base
    self.table_name = "activity_details"
  end

  DETAIL_FIELDS = %w[
    description executors notes pending_confirmations screen audio room_lighting
    stage_lighting aisle_lighting requirements radios media_files commission
    arena_questions general_questions
  ].freeze

  def up
    ActivityDetailRecord.transaction do
      errors = []
      copies = []

      ProductionDetailRecord.find_each do |production|
        unless ActivityRecord.exists?(id: production.act_id, kind: "act")
          errors << "ProductionDetail #{production.id}: act_id=#{production.act_id} does not reference an act"
        end
      end

      ActivityRecord.find_each do |activity|
        json = activity.details
        unless json.is_a?(Hash)
          errors << "Activity #{activity.id}: details must be an object"
          next
        end

        unknown_fields = json.keys - DETAIL_FIELDS
        if unknown_fields.any?
          errors << "Activity #{activity.id}: unknown details keys: #{unknown_fields.join(', ')}"
        end

        attributes = json.slice(*DETAIL_FIELDS)
        attributes.each do |field, value|
          unless value.nil? || value.is_a?(String)
            errors << "Activity #{activity.id}: details.#{field} must be text or null"
          end
        end

        if activity.kind == "act"
          production = ProductionDetailRecord.find_by(act_id: activity.id)
          if production
            attributes = merge_attributes(
              production.attributes.slice(*DETAIL_FIELDS), attributes,
              "Activity #{activity.id}: production_details and details", errors
            )
          end
        end

        detail = ActivityDetailRecord.find_or_initialize_by(activity_id: activity.id)
        merged = merge_attributes(
          detail.attributes.slice(*DETAIL_FIELDS), attributes,
          "Activity #{activity.id}: activity_details and source data", errors
        )
        next unless merged.values.any?(&:present?)

        detail.assign_attributes(merged)
        copies << detail if detail.new_record? || detail.changed?
      end

      if errors.any?
        raise ActiveRecord::MigrationError, "Activity details backfill aborted; no data copied:\n#{errors.join("\n")}"
      end

      copies.each(&:save!)
      say "Copied details for #{copies.size} activities; original sources were preserved"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Copied details may have been edited; original sources were preserved"
  end

  private

  def merge_attributes(preferred, fallback, context, errors)
    preferred.merge(fallback) do |field, primary, secondary|
      if primary.present? && secondary.present? && primary != secondary
        errors << "#{context} conflict on #{field}"
      end

      primary.present? ? primary : (secondary.presence || primary || secondary)
    end
  end
end

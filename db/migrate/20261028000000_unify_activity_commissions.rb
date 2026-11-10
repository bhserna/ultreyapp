class UnifyActivityCommissions < ActiveRecord::Migration[8.1]
  class ActivityRecord < ActiveRecord::Base
    self.table_name = "activities"
  end

  class ActivityDetailRecord < ActiveRecord::Base
    self.table_name = "activity_details"
  end

  COMMISSION_MAPPING = {
    "AC" => [ "AC" ],
    "Hosp" => [ "Hosp" ],
    "EyA" => [ "EyA" ],
    "Liturgia" => [ "Liturgia" ],
    "Marketing" => [ "Marketing" ],
    "Programa" => [ "Programa" ],
    "AC y Hosp" => [ "AC", "Hosp" ],
    "Javier Ayala" => [ "Javier Ayala" ],
    "Todas las comisiones" => [ "Todas las comisiones" ]
  }.freeze
  COMMISSION_QUESTION = "Quién los recibe Programa o EyA?".freeze

  def up
    ActivityRecord.transaction do
      errors = []
      changes = []

      ActivityRecord.find_each do |activity|
        commissions = activity.commissions
        unless commissions.is_a?(Array) && commissions.all? { |value| value.is_a?(String) && value.present? }
          errors << "Activity #{activity.id}: commissions must be an array of nonblank strings"
          next
        end

        unless activity.details.is_a?(Hash)
          errors << "Activity #{activity.id}: details must be an object"
          next
        end

        detail = ActivityDetailRecord.find_or_initialize_by(activity_id: activity.id)
        sources = [ activity.details["commission"], detail.commission ].compact.uniq
        sources.each do |text|
          unless text.is_a?(String)
            errors << "Activity #{activity.id}: commission text must be a string"
            next
          end
          next if text.blank?

          if text == COMMISSION_QUESTION
            preserve_question(detail)
            next
          end

          expected = COMMISSION_MAPPING[text]
          expected ||= [ text ] if commissions.include?(text)
          if expected.nil?
            errors << "Activity #{activity.id}: unrecognized commission text #{text.inspect}"
          elsif commissions.empty?
            commissions = expected.dup
          elsif commissions.sort != expected.sort
            errors << "Activity #{activity.id}: commission text #{text.inspect} conflicts with #{commissions.inspect}"
          end
        end

        activity.commissions = commissions
        changes << activity if activity.changed?
        detail.commission = nil
        if (detail.persisted? || detail.general_questions.present?) && detail.changed?
          changes << detail
        end
      end

      if errors.any?
        raise ActiveRecord::MigrationError, "Commission unification aborted; no data changed:\n#{errors.join("\n")}"
      end

      changes.each(&:save!)
      say "Unified commissions; original JSON wording was preserved"
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Commissions and questions may have been edited after unification"
  end

  private

  def preserve_question(detail)
    existing = detail.general_questions
    return if existing.to_s.include?(COMMISSION_QUESTION)

    detail.general_questions = [ existing.presence, COMMISSION_QUESTION ].compact.join("\n\n")
  end
end

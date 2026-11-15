class SpreadsheetCopy::Program
  class ReadError < StandardError; end

  ROW_TYPES = %w[acts preparations prior_activities].freeze

  def initialize(sheets)
    @sheets = sheets
  end

  def acts
    @acts ||= build_acts
  end

  def preparations
    @preparations ||= build_preparations
  end

  def prior_activities
    @prior_activities ||= build_prior_activities
  end

  def find_act!(day:, id:)
    acts.find { |act| act.day == day && act.to_param == id } ||
      raise(ActiveRecord::RecordNotFound)
  end

  def find_preparation!(day:, id:)
    preparations.find { |preparation| preparation.day == day && preparation.to_param == id } ||
      raise(ActiveRecord::RecordNotFound)
  end

  def find_prior_activity!(day:, id:)
    prior_activities.find { |activity| activity.day == day && activity.to_param == id } ||
      raise(ActiveRecord::RecordNotFound)
  end

  def days
    (prior_activities + acts).map(&:day).uniq
  end

  def acts_for(preparation)
    return [] unless preparation.act_number.present?

    acts.select { |act| act.day == preparation.day && act.number == preparation.act_number }
  end

  def document_keys
    @document_keys ||= acts.group_by(&:source_key).filter_map do |key, matches|
      key if key.present? && matches.one?
    end
  end

  def document_key_for(act)
    act.source_key if document_keys.include?(act.source_key)
  end

  def entries(day:, row_type: nil)
    candidates = case row_type
    when "acts" then acts
    when "preparations" then preparations
    when "prior_activities" then prior_activities
    else prior_activities + preparations + acts
    end

    candidates.select { |entry| entry.day == day }.each_with_index.sort_by do |entry, index|
      type_order = case entry
      when SpreadsheetCopy::PriorActivity then 0
      when SpreadsheetCopy::Preparation then 1
      else 2
      end
      [ entry.schedule.start_minutes || -1, type_order, index ]
    end.map(&:first)
  end

  private

  def build_acts
    sheets = sheets_with_columns(SpreadsheetCopy::Act::COLUMNS.values)
    raise ReadError, "No program sheets found" if sheets.empty?

    sheets.flat_map do |name, rows|
      build_rows(rows, type: SpreadsheetCopy::Act, day: day_from_sheet_name(name))
    end
  end

  def build_preparations
    sheets_with_columns(SpreadsheetCopy::Preparation::REQUIRED_COLUMNS).flat_map do |name, rows|
      day_name = day_from_sheet_name(name)
      day = days.find { |candidate| candidate.casecmp?(day_name) }
      raise ReadError, "Unknown preparation day: #{name}" unless day

      build_rows(rows, type: SpreadsheetCopy::Preparation, day: day)
    end
  end

  def build_prior_activities
    sheets_with_columns(SpreadsheetCopy::PriorActivity::REQUIRED_COLUMNS).flat_map do |name, rows|
      next [] unless name.strip.match?(/\AActividades previas\s+\S/i)

      build_rows(rows, type: SpreadsheetCopy::PriorActivity, day: day_from_sheet_name(name))
    end
  end

  def day_from_sheet_name(name)
    name.strip.sub(/\A(?:Actos|Preparaciones|Actividades previas)\s+/i, "").sub(/\ADom(?=\s)/i, "Domingo")
  end

  def sheets_with_columns(columns)
    @sheets.select do |name, rows|
      rows.any? && columns.all? { |column| rows.first.key?(column) }
    end
  end

  def build_rows(rows, type:, day:)
    after_noon = false
    rows.each_with_index.filter_map do |row, index|
      entry = type.from_row(row, day: day, position: index + 1, after_noon: after_noon)
      next unless entry

      minutes = entry.schedule.start_minutes
      after_noon = true if minutes && minutes >= 12 * 60
      entry
    end
  end
end

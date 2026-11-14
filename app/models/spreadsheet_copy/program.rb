class SpreadsheetCopy::Program
  class ReadError < StandardError; end

  ROW_TYPES = %w[acts preparations].freeze

  def initialize(sheets)
    @sheets = sheets
  end

  def acts
    @acts ||= build_acts
  end

  def preparations
    @preparations ||= build_preparations
  end

  def days
    acts.map(&:day).uniq
  end

  def acts_for(preparation)
    return [] unless preparation.act_number.present?

    acts.select { |act| act.day == preparation.day && act.number == preparation.act_number }
  end

  def entries(day:, row_type: nil)
    candidates = case row_type
    when "acts" then acts
    when "preparations" then preparations
    else acts + preparations
    end

    candidates.select { |entry| entry.day == day }.each_with_index.sort_by do |entry, index|
      [ entry.schedule.start_minutes || -1, entry.is_a?(SpreadsheetCopy::Preparation) ? 0 : 1, index ]
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

  def day_from_sheet_name(name)
    name.strip.sub(/\A(?:Actos|Preparaciones)\s+/i, "").sub(/\ADom(?=\s)/i, "Domingo")
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

class SpreadsheetCopy::Program
  class ReadError < StandardError; end

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

  def entries(day:)
    (acts + preparations).select { |entry| entry.day == day }.each_with_index.sort_by do |entry, index|
      [ entry.schedule.start_minutes || -1, entry.is_a?(SpreadsheetCopy::Preparation) ? 0 : 1, index ]
    end.map(&:first)
  end

  private

  def build_acts
    sheets = sheets_with_columns(SpreadsheetCopy::Act::COLUMNS.values)
    raise ReadError, "No program sheets found" if sheets.empty?

    sheets.flat_map do |day, rows|
      build_rows(rows, type: SpreadsheetCopy::Act, day: day)
    end
  end

  def build_preparations
    sheets_with_columns(SpreadsheetCopy::Preparation::REQUIRED_COLUMNS).flat_map do |name, rows|
      day_name = name.sub(/\APreparaciones\s+/i, "").sub(/\ADom(?=\s)/i, "Domingo")
      day = days.find { |candidate| candidate.casecmp?(day_name) }
      raise ReadError, "Unknown preparation day: #{name}" unless day

      build_rows(rows, type: SpreadsheetCopy::Preparation, day: day)
    end
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

class SpreadsheetCopy::Program
  class ReadError < StandardError; end

  COLUMNS = { schedule: "Horario", number: "# Acto", title: "Actividad" }.freeze

  def initialize(sheets)
    @sheets = sheets
  end

  def acts
    @acts ||= build_acts
  end

  private

  def build_acts
    program_sheets = @sheets.select do |name, rows|
      rows.any? && COLUMNS.values.all? { |column| rows.first.key?(column) }
    end
    raise ReadError, "No program sheets found" if program_sheets.empty?

    program_sheets.flat_map do |day, rows|
      rows.filter_map do |row|
        title = row[COLUMNS[:title]].to_s.strip
        next if title.empty?

        SpreadsheetCopy::Act.new(
          day: day,
          schedule: row[COLUMNS[:schedule]].to_s.strip,
          number: row[COLUMNS[:number]],
          title: title
        )
      end
    end
  end
end

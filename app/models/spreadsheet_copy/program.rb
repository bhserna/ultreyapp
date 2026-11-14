class SpreadsheetCopy::Program
  class ReadError < StandardError; end

  COLUMNS = { schedule: "Horario", number: "# Acto", title: "Actividad" }.freeze
  DETAIL_COLUMNS = {
    audio: "Audio",
    screen: "Video / Pantalla",
    ring: "Anillo",
    lighting: "Iluminación",
    special_effects: "Efectos Especiales",
    pending_files: "Archivos Pendientes",
    ready_files: "Archivos Listos"
  }.freeze

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
      rows.each_with_index.filter_map do |row, index|
        title = row[COLUMNS[:title]].to_s.strip
        next if title.empty?

        SpreadsheetCopy::Act.new(
          day: day,
          position: index + 1,
          schedule: row[COLUMNS[:schedule]].to_s.strip,
          number: row[COLUMNS[:number]],
          title: title,
          **DETAIL_COLUMNS.transform_values { |column| row[column].to_s.strip.presence }
        )
      end
    end
  end
end

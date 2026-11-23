class SpreadsheetCopy::Act < Data.define(:day, :position, :schedule, :number, :title, :source_key,
  :audio, :screen, :ring, :lighting, :special_effects, :pending_files, :ready_files)
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

  def self.from_row(row, day:, position:, after_noon: false)
    title = row[COLUMNS[:title]].to_s.strip
    return if title.empty?

    new(
      day: day,
      position: position,
      schedule: row[COLUMNS[:schedule]],
      after_noon: after_noon,
      number: row[COLUMNS[:number]],
      title: title,
      source_key: row["ID"].to_s.strip.presence,
      **DETAIL_COLUMNS.transform_values { |column| row[column].to_s.strip.presence }
    )
  end

  def initialize(schedule:, number:, after_noon: false, source_key: nil, **fields)
    super(
      schedule: SpreadsheetCopy::ScheduleTime.new(schedule, after_noon: after_noon),
      number: number.is_a?(Numeric) && number == number.to_i ? number.to_i.to_s : number.to_s.presence,
      source_key: source_key,
      **DETAIL_COLUMNS.transform_values { nil },
      **fields
    )
  end

  def to_param
    position.to_s
  end
end

class SpreadsheetCopy::Act
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
      **DETAIL_COLUMNS.transform_values { |column| row[column].to_s.strip.presence }
    )
  end

  attr_reader :day, :position, :schedule, :number, :title,
    :audio, :screen, :ring, :lighting, :special_effects, :pending_files, :ready_files

  def initialize(day:, position:, schedule:, number:, title:, audio: nil, screen: nil, ring: nil,
    lighting: nil, special_effects: nil, pending_files: nil, ready_files: nil, after_noon: false)
    @day = day
    @position = position
    @schedule = SpreadsheetCopy::ScheduleTime.new(schedule, after_noon: after_noon)
    @number = number.is_a?(Numeric) && number == number.to_i ? number.to_i.to_s : number.to_s.presence
    @title = title
    @audio = audio
    @screen = screen
    @ring = ring
    @lighting = lighting
    @special_effects = special_effects
    @pending_files = pending_files
    @ready_files = ready_files
  end

  def to_param
    position.to_s
  end
end

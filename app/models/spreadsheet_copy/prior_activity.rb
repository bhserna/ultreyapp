class SpreadsheetCopy::PriorActivity < Data.define(:day, :position, :schedule, :title, :responsibles, :contact, :notes)
  REQUIRED_COLUMNS = [ "Horario", "Actividad" ].freeze
  DETAIL_COLUMNS = {
    responsibles: "Responsables",
    contact: "Contacto",
    notes: "Notas"
  }.freeze

  def self.from_row(row, day:, position:, after_noon: false)
    title = row["Actividad"].to_s.strip
    return if title.empty?

    new(
      day: day,
      position: position,
      schedule: row["Horario"],
      after_noon: after_noon,
      title: title,
      **DETAIL_COLUMNS.transform_values { |column| row[column].to_s.strip.presence }
    )
  end

  def initialize(schedule:, after_noon: false, **fields)
    super(
      schedule: SpreadsheetCopy::ScheduleTime.new(schedule, after_noon: after_noon),
      **DETAIL_COLUMNS.transform_values { nil },
      **fields
    )
  end

  def to_param
    position.to_s
  end
end

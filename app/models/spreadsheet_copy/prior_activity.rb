class SpreadsheetCopy::PriorActivity
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

  attr_reader :day, :position, :schedule, :title, :responsibles, :contact, :notes

  def initialize(day:, position:, schedule:, title:, responsibles: nil, contact: nil, notes: nil, after_noon: false)
    @day = day
    @position = position
    @schedule = SpreadsheetCopy::ScheduleTime.new(schedule, after_noon: after_noon)
    @title = title
    @responsibles = responsibles
    @contact = contact
    @notes = notes
  end

  def to_param
    position.to_s
  end
end

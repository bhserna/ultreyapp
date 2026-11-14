class SpreadsheetCopy::Preparation
  REQUIRED_COLUMNS = [ "Nombre del Acto", "Previo al Acto #" ].freeze

  def self.from_row(row, day:, position:, after_noon: false)
    title = row["Nombre del Acto"].to_s.strip
    return if title.empty?

    new(
      day: day,
      position: position,
      schedule: row["Horario de Preparación"],
      after_noon: after_noon,
      act_number: row["Previo al Acto #"],
      title: title
    )
  end

  attr_reader :day, :position, :schedule, :act_number, :title

  def initialize(day:, position:, schedule:, act_number:, title:, after_noon: false)
    @day = day
    @position = position
    @schedule = SpreadsheetCopy::ScheduleTime.new(schedule, after_noon: after_noon)
    @act_number = act_number.is_a?(Numeric) && act_number == act_number.to_i ? act_number.to_i.to_s : act_number.to_s.presence
    @title = title
  end
end

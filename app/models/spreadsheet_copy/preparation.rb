class SpreadsheetCopy::Preparation < Data.define(:day, :position, :schedule, :act_number, :title,
  :previous_acts_instructions, :stage_crew_instructions, :choir_instructions, :pending_items)
  REQUIRED_COLUMNS = [ "Nombre del Acto", "Previo al Acto #" ].freeze
  DETAIL_COLUMNS = {
    previous_acts_instructions: "Actividad para Actos Previos",
    stage_crew_instructions: "Actividad para Tramoya",
    choir_instructions: "Actividad para Ambientación Coro Arcoiris",
    pending_items: "Pendientes"
  }.freeze

  def self.from_row(row, day:, position:, after_noon: false)
    title = row["Nombre del Acto"].to_s.strip
    return if title.empty?

    new(
      day: day,
      position: position,
      schedule: row["Horario de Preparación"],
      after_noon: after_noon,
      act_number: row["Previo al Acto #"],
      title: title,
      **DETAIL_COLUMNS.transform_values { |column| row[column].to_s.strip.presence }
    )
  end

  def initialize(schedule:, act_number:, after_noon: false, **fields)
    super(
      schedule: SpreadsheetCopy::ScheduleTime.new(schedule, after_noon: after_noon),
      act_number: act_number.is_a?(Numeric) && act_number == act_number.to_i ? act_number.to_i.to_s : act_number.to_s.presence,
      **DETAIL_COLUMNS.transform_values { nil },
      **fields
    )
  end

  def to_param
    position.to_s
  end
end

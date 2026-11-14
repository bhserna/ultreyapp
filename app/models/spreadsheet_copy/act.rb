class SpreadsheetCopy::Act
  attr_reader :day, :position, :schedule, :number, :title,
    :audio, :screen, :ring, :lighting, :special_effects, :pending_files, :ready_files

  def initialize(day:, position:, schedule:, number:, title:, audio: nil, screen: nil, ring: nil,
    lighting: nil, special_effects: nil, pending_files: nil, ready_files: nil)
    @day = day
    @position = position
    @schedule = schedule
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

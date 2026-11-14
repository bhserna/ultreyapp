class SpreadsheetCopy::Act
  attr_reader :day, :schedule, :number, :title

  def initialize(day:, schedule:, number:, title:)
    @day = day
    @schedule = schedule
    @number = number.is_a?(Numeric) && number == number.to_i ? number.to_i.to_s : number.to_s.presence
    @title = title
  end
end

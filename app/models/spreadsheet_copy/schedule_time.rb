class SpreadsheetCopy::ScheduleTime
  def initialize(value, after_noon: false)
    @after_noon = after_noon
    @text = if value.is_a?(Numeric) && value >= 0 && value < 86_400
      format("%02d:%02d", value.to_i / 3600, value.to_i % 3600 / 60)
    else
      value.to_s.strip
    end
  end

  def to_s
    @text
  end

  def start_minutes
    match = @text.match(/\A(\d{1,2}):(\d{2})(?!\d)(?:\s*(am|pm)\b)?/i)
    return unless match

    hour, minute = match[1].to_i, match[2].to_i
    return unless minute < 60

    if match[3]
      return unless (1..12).cover?(hour)

      hour = hour % 12 + (match[3].downcase == "pm" ? 12 : 0)
    elsif @after_noon && (1..11).cover?(hour)
      hour += 12
    end
    hour * 60 + minute if hour < 24
  end
end

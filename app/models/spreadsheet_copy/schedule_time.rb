class SpreadsheetCopy::ScheduleTime
  TIME_PATTERN = /\d{1,2}:\d{2}(?![\d:])(?:\s*(?:am|pm)\b)?/i

  def initialize(value, after_noon: false)
    @after_noon = after_noon
    @text = source_text(value)
  end

  def to_s
    parts = parse_schedule
    return @text unless parts

    start = minutes_for(parts[:start], fallback_meridiem: meridiem_for(parts[:finish]))
    finish = minutes_for(parts[:finish])
    return @text if start.nil?
    return @text if parts[:finish] && finish.nil?

    text = format_time(start)
    text += "#{parts[:separator]}#{format_time(finish)}" if finish
    text + parts[:annotation]
  end

  def start_minutes
    minutes_for(@text)
  end

  private

  def source_text(value)
    if value.is_a?(Numeric) && value >= 0 && value < 86_400
      format_time(value.to_i / 60)
    else
      value.to_s.strip
    end
  end

  def parse_schedule
    @text.match(/\A
      (?<start>#{TIME_PATTERN})
      (?:\s*(?<separator>[-–])\s*(?<finish>#{TIME_PATTERN}))?
      (?<annotation>.*)
    \z/x)
  end

  def minutes_for(text, fallback_meridiem: nil)
    match = text.to_s.match(/\A(?<hour>\d{1,2}):(?<minute>\d{2})(?!\d)(?:\s*(?<meridiem>am|pm)\b)?/i)
    return unless match

    hour = match[:hour].to_i
    minute = match[:minute].to_i
    return unless minute < 60

    meridiem = match[:meridiem] || fallback_meridiem
    if meridiem
      return unless (1..12).cover?(hour)

      hour = hour % 12 + (meridiem.downcase == "pm" ? 12 : 0)
    elsif @after_noon && (1..11).cover?(hour)
      hour += 12
    end

    hour * 60 + minute if hour < 24
  end

  def meridiem_for(text)
    # A trailing am/pm applies to both endpoints unless the start has its own.
    text.to_s[/\b(am|pm)\z/i, 1]
  end

  def format_time(minutes)
    format("%02d:%02d", minutes / 60, minutes % 60)
  end
end

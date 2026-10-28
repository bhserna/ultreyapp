module ScheduleEntriesHelper
  def schedule_time(value)
    value.to_s.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/) ? value : "—"
  end

  def commission_links(schedule_entry, row_type: nil)
    return "—" if schedule_entry.commissions.empty?

    links = schedule_entry.commissions.map do |commission|
      link_to commission, root_path(day: schedule_entry.day, commission: commission, row_type: row_type)
    end

    content_tag(:span, safe_join(links, ", "), class: "commission-links")
  end
end

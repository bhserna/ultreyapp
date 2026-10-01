module ScheduleEntriesHelper
  def commission_links(schedule_entry)
    return "—" if schedule_entry.commissions.empty?

    links = schedule_entry.commissions.map do |commission|
      link_to commission, root_path(day: schedule_entry.day, commission: commission)
    end

    content_tag(:span, safe_join(links, ", "), class: "commission-links")
  end
end

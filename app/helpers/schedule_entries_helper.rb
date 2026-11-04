module ScheduleEntriesHelper
  def schedule_time(value)
    value.to_s.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/) ? value : "—"
  end

  def commission_links(activity, row_type: nil)
    return "—" if activity.commissions.empty?

    links = activity.commissions.map do |commission|
      link_to commission, root_path(day: activity.day, commission: commission, row_type: row_type)
    end

    content_tag(:span, safe_join(links, ", "), class: "commission-links")
  end
end

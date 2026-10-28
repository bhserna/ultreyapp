AppSelectors.add(:schedule_act, replaces_css: /\.schedule__act(?![\w-])/) do
  xpath do |title = nil|
    rows = XPath.descendant(:tr)[
      XPath.attr(:class).contains_word("schedule__act")
    ]

    title ? rows[XPath.child(:td)[5][XPath.string.n.is(title)]] : rows
  end
end

AppSelectors.add(:schedule_preparation, replaces_css: /\.schedule__preparation(?![\w-])|\[\s*data-preparation-id\b/) do
  xpath do |id = nil|
    rows = XPath.descendant(:tr)[
      XPath.attr(:class).contains_word("schedule__preparation")
    ]

    id ? rows[XPath.attr(:"data-preparation-id") == id.to_s] : rows
  end
end

AppSelectors.add(:schedule_operation, replaces_css: /\.schedule__operation(?![\w-])|\[\s*data-operational-activity-id\b/) do
  xpath do |title_or_id = nil|
    rows = XPath.descendant(:tr)[
      XPath.attr(:class).contains_word("schedule__operation")
    ]

    case title_or_id
    when Integer
      rows[XPath.attr(:"data-operational-activity-id") == title_or_id.to_s]
    when String
      rows[XPath.child(:td)[5][XPath.text.n.is(title_or_id)]]
    else
      rows
    end
  end
end

AppSelectors.add(:schedule_phase, replaces_css: /\.schedule__phase(?![\w-])|\[\s*data-phase\b/) do
  xpath do |phase = nil|
    sections = XPath.descendant(:tbody)[XPath.attr(:"data-phase")]
    phase ? sections[XPath.attr(:"data-phase") == phase.to_s] : sections
  end
end

AppSelectors.add(:schedule_row) do
  xpath { XPath.descendant(:tr)[XPath.child(:td)] }
end

AppSelectors.add(:schedule_cell,
  replaces_css: /\btd\s*:(?:nth-child\(|first-child\b)/,
  within: %i[ schedule_act schedule_preparation schedule_operation schedule_phase schedule_row ]) do
  columns = {
    act_number: 1,
    start_time: 2,
    end_time: 3,
    duration: 4,
    activity: 5,
    commission: 6
  }.freeze

  xpath do |column|
    XPath.descendant(:td)[columns.fetch(column)]
  end
end

Capybara.add_selector(:schedule_act) do
  xpath do |title = nil|
    rows = XPath.descendant(:tbody).descendant(:tr)[
      XPath.attr(:class).contains_word("schedule__act")
    ]

    title ? rows[XPath.child(:td)[5][XPath.string.n.is(title)]] : rows
  end
end

Capybara.add_selector(:schedule_preparation) do
  xpath do |id = nil|
    rows = XPath.descendant(:tbody).descendant(:tr)[
      XPath.attr(:class).contains_word("schedule__preparation")
    ]

    id ? rows[XPath.attr(:"data-preparation-id") == id.to_s] : rows
  end
end

Capybara.add_selector(:schedule_operation) do
  xpath do |title = nil|
    rows = XPath.descendant(:tbody).descendant(:tr)[
      XPath.attr(:class).contains_word("schedule__operation")
    ]

    title ? rows[XPath.child(:td)[5][XPath.text.n.is(title)]] : rows
  end
end

Capybara.add_selector(:schedule_cell) do
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

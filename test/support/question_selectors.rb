Capybara.add_selector(:question) do
  xpath do |body = nil|
    questions = XPath.descendant(:li)[XPath.attr(:class).contains_word("questions__item")]
    body ? questions[XPath.descendant(:p)[XPath.attr(:class).contains_word("questions__body")][XPath.string.n.is(body)]] : questions
  end
end

Capybara.add_selector(:topic_item) do
  xpath do |name = nil|
    topics = XPath.descendant(:li)[XPath.attr(:class).contains_word("topics__management-item")]
    name ? topics[XPath.descendant(:p)[XPath.attr(:class).contains_word("topics__name")][XPath.string.n.is(name)]] : topics
  end
end

Capybara.add_selector(:selected_topic) do
  xpath do |name = nil|
    links = XPath.descendant(:a)[
      XPath.attr(:class).contains_word("topics__tab") & (XPath.attr(:"aria-current") == "page")
    ]
    name ? links[XPath.string.n.is(name)] : links
  end
end

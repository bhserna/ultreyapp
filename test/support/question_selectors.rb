AppSelectors.add(:question, replaces_css: /\.questions__item(?![\w-])/) do
  xpath do |body = nil|
    questions = XPath.descendant(:li)[XPath.attr(:class).contains_word("questions__item")]
    body ? questions[XPath.descendant(:p)[XPath.attr(:class).contains_word("questions__body")][XPath.string.n.is(body)]] : questions
  end
end

AppSelectors.add(:topic_item, replaces_css: /\.topics__management-item(?![\w-])/) do
  xpath do |name = nil|
    topics = XPath.descendant(:li)[XPath.attr(:class).contains_word("topics__management-item")]
    name ? topics[XPath.descendant(:p)[XPath.attr(:class).contains_word("topics__name")][XPath.string.n.is(name)]] : topics
  end
end

AppSelectors.add(:selected_topic, replaces_css: /\.topics__tab(?![\w-])[^,]*\[\s*aria-current\s*=\s*['"]?page\b/) do
  xpath do |name = nil|
    links = XPath.descendant(:a)[
      XPath.attr(:class).contains_word("topics__tab") & (XPath.attr(:"aria-current") == "page")
    ]
    name ? links[XPath.string.n.is(name)] : links
  end
end

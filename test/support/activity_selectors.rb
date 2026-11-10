AppSelectors.add(:activity_details, replaces_css: /\[\s*aria-label\s*=\s*['"]Detalles de la actividad['"]\s*\]/) do
  css do |activity_id = nil|
    selector = "section[aria-label='Detalles de la actividad']"
    activity_id ? "#{selector}[data-activity-id='#{activity_id}']" : selector
  end
end

AppSelectors.add(:activity_metadata, replaces_css: /\.page__details(?![\w-])/) do
  xpath do |label|
    XPath.descendant(:dd)[
      XPath.ancestor(:dl)[XPath.attr(:class).contains_word("page__details")]
    ][XPath.preceding_sibling(:dt)[1][XPath.string.n == label]]
  end
end

AppSelectors.add(:related_act, replaces_css: /\.related-links(?:__(?:label|title))?(?![\w-])/) do
  xpath do |label = nil|
    links = XPath.descendant(:a)[
      XPath.ancestor(:ul)[XPath.attr(:class).contains_word("related-links")]
    ]
    label ? links[XPath.descendant(:span)[XPath.attr(:class).contains_word("related-links__label")][XPath.string.n == label]] : links
  end

  node_filter(:href) { |link, href| link[:href] == href }
end

AppSelectors.add(:detail_field) do
  xpath do |label|
    XPath.descendant(:p)[
      XPath.preceding_sibling(:h3)[1][XPath.string.n == label]
    ]
  end
end

AppSelectors.add(:detail_field) do
  xpath do |label|
    XPath.descendant(:p)[
      XPath.preceding_sibling(:h3)[1][XPath.string.n == label]
    ]
  end
end

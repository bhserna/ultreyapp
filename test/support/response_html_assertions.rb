require_relative "app_selectors"

module ResponseHtmlAssertions
  def within(*args, **options)
    previous_scope = @response_html_scope
    @response_html_scope = response_html_scope.find(*args, **options)
    yield @response_html_scope
  rescue Capybara::ElementNotFound, Capybara::Ambiguous => error
    flunk error.message
  ensure
    @response_html_scope = previous_scope
  end

  def assert_selector(*args, **options, &block)
    self.assertions += 1
    response_html_scope.assert_selector(*args, **options, &block)
  rescue Capybara::ExpectationNotMet => error
    raise Minitest::Assertion, error.message
  end

  def assert_no_selector(*args, **options, &block)
    self.assertions += 1
    response_html_scope.assert_no_selector(*args, **options, &block)
  rescue Capybara::ExpectationNotMet => error
    raise Minitest::Assertion, error.message
  end

  private

  def response_html_scope
    @response_html_scope || Capybara.string(response.body)
  end
end

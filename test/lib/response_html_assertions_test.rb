require "test_helper"
require_relative "../support/response_html_assertions"

class ResponseHtmlAssertionsTest < ActiveSupport::TestCase
  include ResponseHtmlAssertions

  setup do
    @response = Struct.new(:body).new(<<~HTML)
      <main>
        <section id="outer">
          <p id="outer-only">Outer</p>
          <section id="inner">
            <span class="duplicate">First</span>
            <span class="duplicate">Second</span>
          </section>
        </section>
        <p id="outside">Outside</p>
      </main>
    HTML
  end

  test "counts positive and negative selector assertions" do
    previous_count = assertions

    assert_selector "#outside", exact_text: "Outside"
    assert_no_selector "#missing"

    assert_equal previous_count + 2, assertions
  end

  test "nested scopes exclude other elements and restore their parents" do
    within("#outer") do
      assert_no_selector "#outside"
      within("#inner") do |scope|
        assert_equal "inner", scope[:id]
        assert_selector ".duplicate", count: 2
        assert_no_selector "#outer-only"
      end
      assert_selector "#outer-only"
    end

    assert_selector "#outside"
  end

  test "a failed assertion restores the surrounding scope and reports a Minitest failure" do
    within("#outer") do
      failure = assert_raises(Minitest::Assertion) do
        within("#inner") { assert_selector "#missing" }
      end

      assert_includes failure.message, "#missing"
      assert_selector "#outer-only"
      assert_no_selector "#outside"
    end

    assert_selector "#outside"
  end

  test "negative selector failures are counted and reported as Minitest assertions" do
    previous_count = assertions
    failure = assert_raises(Minitest::Assertion) { assert_no_selector "#outside" }

    assert_equal previous_count + 2, assertions
    assert_includes failure.message, "#outside"
  end

  test "missing and ambiguous scopes fail without running the block or losing the parent scope" do
    within("#outer") do
      [ "#missing", ".duplicate" ].each do |selector|
        entered = false
        failure = assert_raises(Minitest::Assertion) do
          within(selector) { entered = true }
        end

        assert_not entered
        assert_includes failure.message, selector
        assert_selector "#outer-only"
        assert_no_selector "#outside"
      end
    end

    assert_selector "#outside"
  end

  test "unexpected block errors propagate and restore the previous scope" do
    assert_raises(RuntimeError) do
      within("#inner") { raise "Unexpected error" }
    end

    assert_selector "#outside"
  end

  test "new responses replace the document instead of reusing old HTML" do
    assert_selector "#outside"

    @response.body = '<p id="replacement">New response</p>'

    assert_selector "#replacement", exact_text: "New response"
    assert_no_selector "#outside"
  end

  test "selector assertions forward filter blocks to Capybara" do
    within("#inner") do
      assert_selector(".duplicate", count: 1) { |node| node.text == "First" }
      assert_no_selector(".duplicate") { |node| node.text == "Missing" }
    end
  end

  private

  attr_reader :response
end

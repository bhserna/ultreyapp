require "test_helper"
require_relative "../support/response_html_assertions"

class ScheduleEntriesControllerTest < ActionDispatch::IntegrationTest
  include ResponseHtmlAssertions

  test "links commissions to acts on the same day" do
    get schedule_entry_url(1)

    assert_response :success
    within(:activity_metadata, "Comisiones") do
      assert_selector ".commission-links", exact_text: "Programa"
      assert_selector :link, "Programa", href: root_path(day: "Domingo 15", commission: "Programa")
    end

    get schedule_entry_url(21)

    assert_response :success
    within(:activity_metadata, "Comisiones") do
      assert_selector :link, "Liturgia", href: root_path(day: "Lunes 16", commission: "Liturgia")
    end
  end

  test "links teardown to all commissions as specified by the source" do
    get schedule_entry_url(31)

    assert_response :success
    within(:activity_metadata, "Comisiones") do
      assert_selector :link, "Todas las comisiones", href: root_path(day: "Lunes 16", commission: "Todas las comisiones")
    end
  end
end

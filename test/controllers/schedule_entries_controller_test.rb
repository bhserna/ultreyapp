require "test_helper"

class ScheduleEntriesControllerTest < ActionDispatch::IntegrationTest
  test "links commissions to acts on the same day" do
    get schedule_entry_url(1)

    assert_response :success
    assert_select ".page__details dt", text: "Comisiones"
    assert_select ".page__details .commission-links", text: "Programa"
    assert_select ".page__details a[href=?]", root_path(day: "Domingo 15", commission: "Programa"), text: "Programa"

    get schedule_entry_url(21)

    assert_response :success
    assert_select ".page__details a[href=?]", root_path(day: "Lunes 16", commission: "Liturgia"), text: "Liturgia"
  end

  test "links teardown to all commissions as specified by the source" do
    get schedule_entry_url(31)

    assert_response :success
    assert_select ".page__details dt", text: "Comisiones"
    assert_select ".page__details a[href=?]", root_path(day: "Lunes 16", commission: "Todas las comisiones"), text: "Todas las comisiones"
  end
end

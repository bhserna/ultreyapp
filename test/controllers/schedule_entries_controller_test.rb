require "test_helper"

class ScheduleEntriesControllerTest < ActionDispatch::IntegrationTest
  test "links every commission to activities on the same day" do
    get schedule_entry_url(1)

    assert_response :success
    assert_select ".activity-page__details dt", text: "Comisiones"
    assert_select ".activity-page__details .commission-links", text: "AC, Hospitalidad"
    assert_select ".activity-page__details .commission-links a", count: 2
    assert_select ".activity-page__details a[href=?]", root_path(day: "Sábado 14", commission: "AC"), text: "AC"
    assert_select ".activity-page__details a[href=?]", root_path(day: "Sábado 14", commission: "Hospitalidad"), text: "Hospitalidad"

    get schedule_entry_url(6)

    assert_response :success
    assert_select ".activity-page__details a[href=?]", root_path(day: "Domingo 15", commission: "Desfile"), text: "Desfile"
    assert_select ".activity-page__details a[href=?]", root_path(day: "Domingo 15", commission: "AC"), text: "AC"
  end

  test "shows a placeholder when the activity has no commission" do
    get schedule_entry_url(49)

    assert_response :success
    assert_select ".activity-page__details dt", text: "Comisiones"
    assert_select ".activity-page__details dd", text: "—"
    assert_select ".activity-page__details .commission-links", count: 0
  end
end

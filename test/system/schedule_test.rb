require "application_system_test_case"

class ScheduleTest < ApplicationSystemTestCase
  test "shows each activity commission separately" do
    visit root_path

    within("tr", text: "Recepción de Diócesis") do
      assert_selector "td:nth-child(5) li", text: "AC"
      assert_selector "td:nth-child(5) li", text: "Hosp"
    end

    click_link "Domingo 15"

    within("tr", text: "Entrada a la Arena") do
      assert_selector "td:nth-child(5) li", text: "Desfile"
      assert_selector "td:nth-child(5) li", text: "AC"
    end

    click_link "Lunes 16"

    within("tr", text: "Desmontaje") do
      assert_selector "td:nth-child(5)", text: "—"
      assert_no_selector "td:nth-child(5) li"
    end
  end
end

require "application_system_test_case"

class PreparationsTest < ApplicationSystemTestCase
  test "show actions" do
    preparation = preparations(:opening_setup)
    first = activities(:chair_setup)
    second = activities(:microphone_setup)
    visit preparation_path(preparation)

    assert_selector "h1", text: preparation.title
    assert_selector :activity_metadata, "Inicio de preparación", text: first.start_time
    sections = all("section.page__section")
    assert_equal [ first.title, second.title ], sections.map { |section| section.first("p").text }
    within(sections.first) do
      assert_selector :activity_metadata, "Inicio de acción", text: first.start_time
      assert_text first.notes
    end
    within(sections.last) do
      assert_selector :activity_metadata, "Inicio de acción", text: second.start_time
      assert_text second.production_detail.audio
    end
  end

  test "go to a related act" do
    preparation = preparations(:opening_setup)
    act = activities(:opening_act)
    visit preparation_path(preparation)

    find(:related_act, "Acto #{act.act_number}").click

    assert_current_path schedule_entry_path(act)
    assert_selector "h1", text: act.title
    click_link "← Volver al programa"
    assert_current_path root_path(day: act.day)
    assert_selector :schedule_act, act.title
  end
end

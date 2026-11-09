require "application_system_test_case"

class ScheduleTest < ApplicationSystemTestCase
  test "show acts" do
    act = activities(:opening_act)
    visit root_path(day: act.day)

    within(:schedule_act, act.title) do
      assert_selector :schedule_cell, :act_number, exact_text: act.act_number.to_s
      assert_selector :schedule_cell, :start_time, exact_text: act.start_time
      assert_selector :schedule_cell, :end_time, exact_text: act.end_time
    end
    assert_no_selector :schedule_act, activities(:next_day_act).title
  end

  test "show preparations" do
    preparation = preparations(:opening_setup)
    visit root_path(day: preparation.day)

    within(:schedule_preparation, preparation.id) do
      assert_selector :schedule_cell, :activity, text: preparation.title
      assert_selector :schedule_cell, :start_time, text: preparation.start_time
      preparation.commissions.each { |commission| assert_link commission }
    end
    assert_no_text activities(:chair_setup).title
    assert_no_text activities(:microphone_setup).title
    assert_no_selector :schedule_preparation, preparations(:next_day_setup).id
  end

  test "show operations" do
    operation = activities(:reception)
    visit root_path(day: operation.day)

    within(:schedule_operation, operation.title) do
      assert_selector :schedule_cell, :act_number, text: "Operación"
      assert_text operation.category
    end
    assert_no_selector :schedule_act, operation.title
    assert_no_selector :schedule_operation, activities(:next_day_operation).title
  end

  test "go to an activity" do
    act = activities(:opening_act)
    operation = activities(:reception)

    visit root_path(day: act.day)
    within(:schedule_act, act.title) { click_link "Ver detalle" }
    assert_current_path schedule_entry_path(act)
    assert_selector "h1", text: act.title

    visit root_path(day: operation.day)
    within(:schedule_operation, operation.title) { click_link "Ver detalle" }
    assert_current_path operational_activity_path(operation.source_id)
    assert_selector "h1", text: operation.title
  end

  test "go to a preparation" do
    preparation = preparations(:opening_setup)
    visit root_path(day: preparation.day)

    within(:schedule_preparation, preparation.id) { click_link "Ver detalle" }

    assert_current_path preparation_path(preparation)
    assert_selector "h1", text: preparation.title
  end

  test "go to a day" do
    act = activities(:next_day_act)
    operation = activities(:next_day_operation)
    preparation = preparations(:next_day_setup)
    visit root_path

    click_link act.day

    assert_selector :schedule_act, act.title
    assert_selector :schedule_operation, operation.title
    assert_selector :schedule_preparation, preparation.id
    assert_no_selector :schedule_act, activities(:opening_act).title
    assert_no_selector :schedule_operation, activities(:reception).title
    assert_no_selector :schedule_preparation, preparations(:opening_setup).id
  end

  test "filter by activity type" do
    visit root_path

    select "Actos", from: "Tipo de actividad"
    assert_selector :schedule_act
    assert_no_selector :schedule_preparation
    assert_no_selector :schedule_operation

    select "Preparaciones", from: "Tipo de actividad"
    assert_selector :schedule_preparation
    assert_no_selector :schedule_act
    assert_no_selector :schedule_operation

    select "Operación", from: "Tipo de actividad"
    assert_selector :schedule_operation
    assert_no_selector :schedule_act
    assert_no_selector :schedule_preparation

    select "Todo", from: "Tipo de actividad"
    assert_selector :schedule_act
    assert_selector :schedule_preparation
    assert_selector :schedule_operation
  end

  test "filter by commission" do
    visit root_path

    select "EyA", from: "Comisión"

    assert_selector :schedule_operation, activities(:sound_check).title
    assert_selector :schedule_preparation, preparations(:opening_setup).id
    assert_no_selector :schedule_act
    assert_no_selector :schedule_operation, activities(:reception).title

    select "Sin filtro de comisión", from: "Comisión"

    assert_selector :schedule_act, activities(:opening_act).title
    assert_selector :schedule_operation, activities(:reception).title
  end

  test "filter from a commission link" do
    operation = activities(:sound_check)
    visit root_path(day: operation.day)

    within(:schedule_operation, operation.title) { click_link "EyA" }

    assert_select "Comisión", selected: "EyA"
    assert_selector :schedule_operation, operation.title
    assert_no_selector :schedule_operation, activities(:reception).title
    assert_no_selector :schedule_act
  end

  test "keep filters when changing days" do
    visit root_path
    select "Operación", from: "Tipo de actividad"
    assert_no_selector :schedule_act
    select "EyA", from: "Comisión"
    assert_selector :schedule_operation, activities(:sound_check).title

    click_link activities(:next_day_act).day

    assert_select "Tipo de actividad", selected: "Operación"
    assert_select "Comisión", selected: "EyA"
    assert_text "No hay actividades de esta comisión para Lunes 16."
    assert_no_selector :schedule_act
    assert_no_selector :schedule_operation
    assert_no_selector :schedule_preparation
  end

  test "use filters on a narrow screen" do
    page.driver.browser.manage.window.resize_to(390, 900)
    visit root_path

    assert evaluate_script("Array.from(document.querySelectorAll('.filter select')).every(select => { const bounds = select.getBoundingClientRect(); return bounds.left >= 0 && bounds.right <= window.innerWidth })")
    select "Operación", from: "Tipo de actividad"
    assert_no_selector :schedule_act
    select "EyA", from: "Comisión"

    assert_selector :schedule_operation, activities(:sound_check).title
    assert_no_selector :schedule_operation, activities(:reception).title
    assert_no_selector :schedule_preparation
  ensure
    page.driver.browser.manage.window.resize_to(1400, 900)
  end
end

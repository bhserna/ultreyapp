require "application_system_test_case"

class PreparationActivityPersistenceTest < ApplicationSystemTestCase
  test "shows persisted action information inside its preparation and filters by its commission" do
    action = Activity.find(48)
    action.update!(
      title: "Acción actualizada en la base de datos", start_time: "09:40", commissions: [ "Equipo de preparación" ],
      details: action.details.merge("executors" => "Equipo asignado", "notes" => "Notas actualizadas", "audio" => "Audio actualizado")
    )

    visit root_path(day: "Domingo 15", commission: "Equipo de preparación", row_type: "preparations")
    assert_selector :schedule_preparation, count: 1
    within(:schedule_preparation, 2) do
      assert_selector :schedule_cell, :start_time, text: "09:40"
      click_link "Ver detalle"
    end

    assert_current_path preparation_path(2)
    assert_selector "h1", text: "Preparación para el Acto 1 y 2"
    assert_text "Acción actualizada en la base de datos"
    assert_text "Equipo asignado"
    assert_text "Notas actualizadas"
    assert_text "Audio actualizado"
    assert_selector :activity_metadata, "Inicio de preparación", text: "09:40"
    assert_selector :related_act, "Acto 1"
    assert_selector :related_act, "Acto 2"
    assert_no_link "Editar acción"

    visit preparation_path(3)
    assert_no_text "Acción actualizada en la base de datos"
    assert_no_text "Notas actualizadas"

    visit schedule_entry_path(1)
    assert_no_text "Acción actualizada en la base de datos"
    assert_no_text "Notas actualizadas"
  end

  test "uses explicit action positions rather than IDs or source row order" do
    first = Activity.find(48)
    second = Activity.find(49)
    first.update!(position: 3, title: "Acción ahora en segundo lugar")
    second.update!(position: 1, title: "Acción ahora en primer lugar", start_time: "09:42")
    first.update!(position: 2)

    visit preparation_path(2)
    sections = all("section.page__section")
    assert_includes sections.first.text, "Acción ahora en primer lugar"
    assert_includes sections.last.text, "Acción ahora en segundo lugar"
    assert_selector :activity_metadata, "Inicio de preparación", text: "09:42"
    assert_selector :related_act, "Acto 1"
    assert_selector :related_act, "Acto 2"
  end

  test "shows persisted preparation headers and related acts in the schedule and detail page" do
    preparation = preparations(:opening_acts)
    act = activities(:activity_3)
    preparation.update!(
      title: "Preparación guardada en la base de datos", day: "Lunes 16", phase: "before_parade",
      start_time: "07:15", act_ids: [ act.id ]
    )
    preparation.actions.first.update!(start_time: nil, commissions: [ "Equipo especial" ])

    visit root_path(day: "Lunes 16", commission: "Equipo especial", row_type: "preparations")
    assert_selector :schedule_preparation, count: 1
    within(:schedule_phase, "before_parade") do
      within(:schedule_preparation, preparation.id) do
        assert_selector :schedule_cell, :activity, text: "Preparación guardada en la base de datos"
        assert_selector :schedule_cell, :start_time, text: "07:15"
        click_link "Ver detalle"
      end
    end

    assert_current_path preparation_path(preparation)
    assert_selector "h1", text: "Preparación guardada en la base de datos"
    assert_selector ".page__eyebrow", text: /Lunes 16/i
    assert_selector :activity_metadata, "Inicio de preparación", text: "07:15"
    assert_selector :related_act, "Acto 3"
    assert_no_selector :related_act, "Acto 1"
    assert_no_selector :related_act, "Acto 2"
    assert_no_link "Editar preparación"

    click_link "Acto 3"
    assert_current_path schedule_entry_path(act)
  end
end

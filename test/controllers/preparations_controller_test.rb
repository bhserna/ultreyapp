require "test_helper"

class PreparationsControllerTest < ActionDispatch::IntegrationTest
  test "shows preparation actions and links to each related act" do
    get preparation_url(2)

    assert_response :success
    assert_select "h1", text: "Preparación para el Acto 1 y 2"
    assert_select "section.page__section", count: 2
    assert_select "section.page__section:nth-of-type(1)", text: /Tener disponibles 10 sillas/
    assert_select "section.page__section:nth-of-type(2)", text: /Pista Popurri/
    assert_select "section.page__section h2", count: 0
    assert_select "p", text: "Tener disponibles 10 sillas"
    assert_select "a[href=?]", schedule_entry_path(1)
    assert_select "a[href=?]", schedule_entry_path(2)
    assert_select "a[href=?]", root_path(day: "Domingo 15"), text: "← Volver al programa"

    get schedule_entry_url(1)
    assert_select "h2", text: "Preparaciones", count: 0
    assert_select "p", text: "Tener disponibles 10 sillas", count: 0
  end

  test "shows preparations without related acts and rejects missing preparations" do
    get preparation_url(1)
    assert_response :success
    assert_select "h1", text: "Actividades en la Arena previo a que llegue el desfile"
    assert_select "h2", text: "Actos relacionados", count: 0

    get preparation_url(999)
    assert_response :not_found
  end
end

require "test_helper"

class OperationalActivitiesControllerTest < ActionDispatch::IntegrationTest
  test "shows the source details without treating the operation as an act" do
    get operational_activity_url(11)

    assert_response :success
    assert_select "h1", text: "Preparación para la transmisión en vivo"
    assert_select ".page__details dd", text: "Servicios y proveedores"
    assert_select ".page__details dd", text: "07:00"
    assert_select "h3", text: "Preguntas para la Arena"
    assert_select "h3", text: "Dudas generales"
    assert_select "a[href=?]", root_path(day: "Domingo 15", commission: "EyA"), text: "EyA"
    assert_select "turbo-frame#questions", count: 0
    assert_select "turbo-frame#documents", count: 0
  end

  test "returns not found for an unknown operation" do
    get operational_activity_url(999)
    assert_response :not_found
  end
end

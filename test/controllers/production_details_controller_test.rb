require "test_helper"

class ProductionDetailsControllerTest < ActionDispatch::IntegrationTest
  test "creates details under the activity in the URL and rejects duplicates" do
    assert_difference("ProductionDetail.count", 1) do
      post schedule_entry_production_detail_url(3), params: {
        production_detail: { executors: "EyA", schedule_entry_id: 4 }
      }
    end
    assert_redirected_to schedule_entry_url(3)
    detail = ProductionDetail.find_by!(schedule_entry_id: 3)
    assert_equal "EyA", detail.executors

    assert_no_difference("ProductionDetail.count") do
      post schedule_entry_production_detail_url(3), params: { production_detail: { executors: "Otro equipo" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    assert_equal "EyA", detail.reload.executors
  end

  test "keeps reading updating and deleting scoped to the activity" do
    detail = ProductionDetail.create!(schedule_entry_id: 3, notes: "Solo actividad tres")

    get schedule_entry_url(4)
    assert_select "p", text: "Solo actividad tres", count: 0
    get edit_schedule_entry_production_detail_url(4)
    assert_response :not_found
    patch schedule_entry_production_detail_url(4), params: { production_detail: { notes: "Cambio" } }
    assert_response :not_found
    delete schedule_entry_production_detail_url(4)
    assert_response :not_found
    assert_equal "Solo actividad tres", detail.reload.notes

    patch schedule_entry_production_detail_url(3), params: { production_detail: { notes: "Actualizado", schedule_entry_id: 4 } }
    assert_redirected_to schedule_entry_url(3)
    assert_equal "Actualizado", detail.reload.notes
    assert_equal 3, detail.schedule_entry_id

    assert_difference("ProductionDetail.count", -1) { delete schedule_entry_production_detail_url(3) }
    assert_redirected_to schedule_entry_url(3)
  end

  test "rejects activities that do not exist in the schedule" do
    get new_schedule_entry_production_detail_url(999)
    assert_response :not_found

    assert_no_difference("ProductionDetail.count") do
      post schedule_entry_production_detail_url(999), params: { production_detail: { audio: "Prueba" } }
    end
    assert_response :not_found
  end
end

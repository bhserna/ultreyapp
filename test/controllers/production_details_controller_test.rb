require "application_request_test_case"

class ProductionDetailsControllerTest < ApplicationRequestTestCase
  test "create under the act in the URL" do
    act = activities(:opening_act)

    assert_difference "ProductionDetail.count", 1 do
      post schedule_entry_production_detail_url(act), params: {
        production_detail: { notes: "Notas guardadas", act_id: activities(:closing_act).id }
      }
    end

    detail = ProductionDetail.order(:id).last
    assert_equal act.id, detail.act_id
    assert_equal "Notas guardadas", detail.notes
    assert_redirected_to schedule_entry_url(act)
  end

  test "protect the act association on update" do
    act = activities(:opening_act)
    detail = ProductionDetail.create!(act_id: act.id, notes: "Notas originales")
    original_attributes = detail.attributes.except("notes", "updated_at")

    patch schedule_entry_production_detail_url(act), params: {
      production_detail: { notes: "Notas actualizadas", act_id: activities(:closing_act).id }
    }

    assert_redirected_to schedule_entry_url(act)
    assert_equal "Notas actualizadas", detail.reload.notes
    assert_equal original_attributes, detail.attributes.except("notes", "updated_at")
  end

  test "reject access through another act" do
    detail = ProductionDetail.create!(act_id: activities(:opening_act).id, notes: "Notas originales")
    original_attributes = detail.attributes
    other_act = activities(:closing_act)

    assert_no_difference "ProductionDetail.count" do
      get edit_schedule_entry_production_detail_url(other_act)
      assert_response :not_found
      patch schedule_entry_production_detail_url(other_act), params: { production_detail: { notes: "Notas manipuladas" } }
      assert_response :not_found
      delete schedule_entry_production_detail_url(other_act)
      assert_response :not_found
    end

    assert_equal original_attributes, detail.reload.attributes
  end

  test "reject duplicate details" do
    act = activities(:opening_act)
    detail = ProductionDetail.create!(act_id: act.id, executors: "Equipo asignado", notes: "Notas originales")
    original_attributes = detail.attributes

    assert_no_difference "ProductionDetail.count" do
      post schedule_entry_production_detail_url(act), params: { production_detail: { notes: "Notas duplicadas" } }
    end

    assert_response :unprocessable_entity
    assert_select "form[action=?]", schedule_entry_production_detail_path(act)
    assert_select "[role=alert]"
    assert_select "textarea[name='production_detail[notes]']", text: "Notas duplicadas"
    assert_equal original_attributes, detail.reload.attributes
  end
end

require "test_helper"

class ProductionDetailsControllerTest < ActionDispatch::IntegrationTest
  test "redirect old production forms to the common forms" do
    act = activities(:opening_act)

    get new_schedule_entry_production_detail_url(act)
    assert_redirected_to new_activity_activity_detail_url(act)

    get edit_schedule_entry_production_detail_url(act)
    assert_redirected_to edit_activity_activity_detail_url(act)
  end

  test "disable writes to the old production endpoints" do
    act = activities(:opening_act)
    detail = ProductionDetail.create!(act_id: act.id, notes: "Original notes")
    original = detail.attributes
    legacy_url = "/schedule_entries/#{act.id}/production_detail"

    assert_no_difference [ "ProductionDetail.count", "ActivityDetail.count" ] do
      post legacy_url, params: { production_detail: { notes: "Rejected notes" } }
      assert_response :not_found
      patch legacy_url, params: { production_detail: { notes: "Rejected notes" } }
      assert_response :not_found
      delete legacy_url
      assert_response :not_found
    end

    assert_equal original, detail.reload.attributes
  end
end

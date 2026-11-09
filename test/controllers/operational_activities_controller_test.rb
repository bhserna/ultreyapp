require "test_helper"

class OperationalActivitiesControllerTest < ActionDispatch::IntegrationTest
  test "resolve operations by source ID" do
    operation = activities(:reception)
    act = activities(:opening_act)
    assert_equal act.id, operation.source_id
    assert_not_equal operation.id, operation.source_id

    get operational_activity_url(operation.source_id)

    assert_response :success
    assert_select "h1", text: operation.title
    assert_select "h1", text: act.title, count: 0
  end

  test "reject an unknown operation" do
    operation = activities(:reception)
    assert_not Activity.operations.exists?(source_id: operation.id)

    get operational_activity_url(operation.id)

    assert_response :not_found
  end
end

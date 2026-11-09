require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  test "select activities by kind" do
    assert_equal [ activities(:opening_act), activities(:closing_act), activities(:next_day_act) ], Activity.acts.to_a
    assert_equal [ activities(:reception), activities(:sound_check), activities(:next_day_operation) ], Activity.operations.to_a
    assert_equal [ activities(:microphone_setup), activities(:chair_setup) ].sort_by(&:id), Activity.preparation_actions.order(:id).to_a
  end

  test "find an operation by source ID" do
    operation = activities(:reception)

    assert_not_equal operation.id, operation.source_id
    assert_equal activities(:opening_act).id, operation.source_id
    assert_equal operation, Activity.find_operation_by_source_id(operation.source_id)
  end

  test "validate required attributes" do
    activity = Activity.new(title: "", day: "", source_id: nil, kind: "unknown", phase: "unknown")

    assert_not activity.valid?
    %i[title day source_id].each { |attribute| assert activity.errors.of_kind?(attribute, :blank) }
    %i[kind phase].each { |attribute| assert activity.errors.of_kind?(attribute, :inclusion) }
  end

  test "keep source IDs unique within each kind" do
    duplicate = activities(:opening_act).dup

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:source_id, :taken)

    duplicate.source_id = Activity.maximum(:source_id) + 1
    duplicate.save!
    operation = activities(:reception).dup
    operation.source_id = duplicate.source_id

    assert operation.valid?
  end

  test "require a preparation for actions" do
    action = activities(:chair_setup)
    action.preparation_id = Preparation.maximum(:id) + 1

    assert_not action.valid?
    assert action.errors.of_kind?(:preparation, :blank)

    action.preparation_id = nil
    assert_not action.valid?
    assert action.errors.of_kind?(:preparation_id, :not_a_number)

    action.preparation = preparations(:opening_setup)
    [ nil, 0, -1, 1.5 ].each do |position|
      action.position = position
      assert_not action.valid?
      assert action.errors[:position].present?
    end
  end

  test "keep action positions unique within a preparation" do
    action = activities(:chair_setup)
    action.position = activities(:microphone_setup).position

    assert_not action.valid?
    assert action.errors.of_kind?(:position, :taken)

    action.preparation = preparations(:next_day_setup)
    assert action.valid?
  end

  test "restrict grouping to preparation actions" do
    [ activities(:opening_act), activities(:reception) ].each do |activity|
      activity.preparation = preparations(:opening_setup)
      activity.position = 1

      assert_not activity.valid?
      assert activity.errors.of_kind?(:preparation_id, :present)
      assert activity.errors.of_kind?(:position, :present)
    end
  end
end

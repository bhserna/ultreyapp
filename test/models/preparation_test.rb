require "test_helper"

class PreparationTest < ActiveSupport::TestCase
  test "validate required attributes" do
    preparation = Preparation.new(title: "", day: "", phase: "unknown")

    assert_not preparation.valid?
    assert preparation.errors.of_kind?(:title, :blank)
    assert preparation.errors.of_kind?(:day, :blank)
    assert preparation.errors.of_kind?(:phase, :inclusion)
  end

  test "allow only act references" do
    preparation = preparations(:opening_setup)
    unknown_id = Activity.maximum(:id) + 1
    invalid_references = [
      nil, {}, [ "1" ], [ 0 ], [ unknown_id ],
      [ activities(:reception).id ], [ activities(:chair_setup).id ]
    ]

    invalid_references.each do |act_ids|
      preparation.act_ids = act_ids
      assert_not preparation.valid?
      assert preparation.errors.of_kind?(:act_ids, :invalid)
    end

    preparation.act_ids = []
    assert preparation.valid?
    preparation.act_ids = [ activities(:opening_act).id, activities(:closing_act).id ]
    assert preparation.valid?
  end

  test "order actions by position" do
    preparation = preparations(:opening_setup)
    first = activities(:chair_setup)
    second = activities(:microphone_setup)
    other_action = second.dup
    other_action.source_id = Activity.maximum(:source_id) + 1
    other_action.preparation = preparations(:next_day_setup)
    other_action.save!

    assert_operator first.id, :>, second.id
    assert_equal [ first, second ], preparation.actions.to_a
    assert_not_includes preparation.actions, other_action
  end

  test "use the first action start time" do
    preparation = preparations(:opening_setup)
    first = activities(:chair_setup)
    first.update!(start_time: "10:00")
    activities(:microphone_setup).update!(start_time: "08:00")

    assert_equal first.start_time, preparation.start_time
  end

  test "fall back to the preparation start time" do
    preparation = preparations(:opening_setup)
    activities(:chair_setup).update!(start_time: nil)
    activities(:microphone_setup).update!(start_time: "08:00")

    assert_equal preparation[:start_time], preparation.start_time

    empty_preparation = preparations(:next_day_setup)
    assert_empty empty_preparation.actions
    assert_equal empty_preparation[:start_time], empty_preparation.start_time
  end

  test "collect unique action commissions" do
    preparation = preparations(:opening_setup)
    activities(:chair_setup).update!(commissions: [ "EyA", "Programa" ])
    activities(:microphone_setup).update!(commissions: [ "Programa" ])

    assert_equal [ "EyA", "Programa" ], preparation.commissions
    assert_empty preparations(:next_day_setup).commissions
  end

  test "prevent deletion with actions" do
    preparation = preparations(:opening_setup)
    original_actions = preparation.actions.map(&:attributes)

    assert_no_difference [ "Preparation.count", "Activity.count" ] do
      assert_not preparation.destroy
    end

    assert Preparation.exists?(preparation.id)
    assert_equal original_actions, preparation.reload.actions.map(&:attributes)
  end
end

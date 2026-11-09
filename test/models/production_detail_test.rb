require "test_helper"

class ProductionDetailTest < ActiveSupport::TestCase
  test "require an act reference" do
    detail = ProductionDetail.new

    assert_not detail.valid?
    assert detail.errors.of_kind?(:act_id, :blank)
  end

  test "allow one detail per act" do
    act = activities(:opening_act)
    ProductionDetail.create!(act_id: act.id)
    duplicate = ProductionDetail.new(act_id: act.id)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:act_id, :taken)

    duplicate.act_id = activities(:closing_act).id
    assert duplicate.valid?
  end
end

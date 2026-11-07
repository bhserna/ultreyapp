require "test_helper"

class PreparationTest < ActiveSupport::TestCase
  test "groups persisted action activities and preserves their order and related acts" do
    preparations = Preparation.order(:id)
    actions = preparations.flat_map(&:actions)

    assert_equal (1..26).to_a, preparations.map(&:id)
    assert_equal 32, actions.size
    assert_equal (45..76).to_a, actions.map(&:id)
    assert actions.all? { |action| action.persisted? && action.kind == "preparation_action" }
    assert actions.all? { |action| action.title.present? }
    assert_empty preparations.first.act_ids
    preparations.flat_map(&:act_ids).each { |id| assert Activity.acts.find(id) }

    preparations.each do |preparation|
      assert_equal (1..preparation.actions.size).to_a, preparation.actions.map(&:position)
      preparation.actions.each do |action|
        assert_equal preparation.id, action.preparation_id
        assert_equal preparation.id, action.preparation.id
        assert_equal preparation.day, action.day
        assert_equal preparation.phase, action.phase
      end
    end
  end

  test "preserves undecided start times without treating questions as commissions" do
    preparation = Preparation.create!(
      "id" => 100, "title" => "Sin horario", "day" => "Domingo 15", "start_time" => nil,
      "act_ids" => []
    )
    Activity.create!(
      kind: "preparation_action", preparation_id: 100, position: 1, source_id: 100,
      title: "Example action", day: "Domingo 15", start_time: "Por definir",
      details: { "commission" => "¿Quién lo prepara?" }
    )

    assert_equal "Por definir", preparation.start_time
    assert_empty preparation.commissions
    assert_equal "¿Quién lo prepara?", preparation.actions.first.details.fetch("commission")
    assert_equal "Por definir con Programa", Preparation.all.first.start_time
  end

  test "finds preparations by route ID and preserves shared act references" do
    assert_equal [ 1, 2 ], Preparation.find("2").act_ids
    assert_equal [ 7, 8, 9, 10 ], Preparation.find(7).act_ids
    assert_equal [ 16 ], Preparation.find(13).act_ids
    assert_equal [ 20 ], Preparation.find(17).act_ids
    assert_equal [ 20 ], Preparation.find(18).act_ids
    assert_equal [ 27 ], Preparation.find(24).act_ids
    assert_includes Preparation.find(24).title, "Acto 24 / Vivencia 6"
    assert_equal [ 29 ], Preparation.find(26).act_ids
    assert_raises(ActiveRecord::RecordNotFound) { Preparation.find(999) }
  end

  test "uses the first action start time and keeps the header when the action has none" do
    Preparation.all.each do |item|
      first_start = item.actions.first.start_time
      assert_equal first_start, item.start_time if first_start.present?
    end
    preparation = Preparation.find(7)
    assert_equal "12:30", preparation.start_time
    assert_equal "12:30", preparation.actions.first.start_time
    assert_equal "12:45", preparation.actions.first.end_time

    furniture = Preparation.find(3).actions.last
    assert_equal "10:00", furniture.start_time
    assert_equal "10:20", furniture.end_time
    assert_equal "1-2 min", furniture.duration

    next_day = Preparation.find(17)
    assert_equal "Domingo 15", next_day.day
    assert_equal "19:00", next_day.start_time
    assert_nil next_day.actions.first.start_time
    assert_includes next_day.actions.first.title, "2 reclinatorios"

    monday = Preparation.find(18)
    assert_equal "Lunes 16", monday.day
    assert_equal "07:40", monday.start_time
    assert_nil monday.actions.first.start_time
    assert_equal "21:30", Preparation.find(20).start_time
    assert_equal "11:05", Preparation.find(24).start_time
  end

  test "does not render action activities as separate schedule rows" do
    [ "Sábado 14", "Domingo 15", "Lunes 16" ].each do |day|
      rows = Schedule.new(day: day, commission: nil).rows
      assert rows.grep(Activity).none? { |activity| activity.kind == "preparation_action" }
    end
  end

  test "requires a group and a unique positive position only for preparation actions" do
    action = Activity.find(48)
    action.preparation_id = nil
    action.position = 0
    assert_not action.valid?
    assert action.errors.of_kind?(:preparation_id, :not_a_number)
    assert action.errors.of_kind?(:position, :greater_than)

    duplicate = Activity.find(49).dup
    duplicate.source_id = 100
    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:position, :taken)

    act = Activity.find(1)
    act.preparation_id = 2
    act.position = 1
    assert_not act.valid?
    assert act.errors.of_kind?(:preparation_id, :present)
    assert act.errors.of_kind?(:position, :present)
  end

  test "uses action details through the common interface rather than act production records" do
    action = Activity.find(48)
    ProductionDetail.create!(act_id: action.id, executors: "Unrelated team", notes: "Unrelated notes")
    ProductionDetail.create!(act_id: action.preparation_id, executors: "Act team", notes: "Act notes")

    assert_equal "EyA", action.executors
    assert_equal "Tener disponibles 10 sillas", action.notes
    assert_instance_of ProductionInformation, action.production_detail
    assert_equal action.details.symbolize_keys.slice(*ProductionInformation.members), action.production_detail.to_h
    assert_equal "Utilizacion de Pantalla completa", Activity.find(49).production_detail.screen
  end

  test "keeps a preparation group when no actions remain" do
    Activity.preparation_actions.where(preparation_id: 2).delete_all
    preparation = Preparation.find(2)

    assert_empty preparation.actions
    assert_empty preparation.commissions
    assert_equal "09:45", preparation.start_time
    assert_equal [ 1, 2 ], preparation.act_ids
  end

  test "validates required fields phase and references to acts only" do
    preparation = Preparation.new(title: "", day: "", phase: "unknown")

    assert_not preparation.valid?
    assert preparation.errors.of_kind?(:title, :blank)
    assert preparation.errors.of_kind?(:day, :blank)
    assert preparation.errors.of_kind?(:phase, :inclusion)

    preparation.assign_attributes(title: "New preparation", day: "Domingo 15", phase: "program")
    [ [ activities(:activity_32).id ], [ activities(:activity_48).id ], [ 999 ], [ "1" ], nil, {} ].each do |act_ids|
      preparation.act_ids = act_ids
      assert_not preparation.valid?
      assert preparation.errors.of_kind?(:act_ids, :invalid)
    end

    preparation.act_ids = [ activities(:activity_1).id ]
    assert preparation.valid?
    preparation.act_ids = []
    assert preparation.valid?
  end

  test "uses the persisted header time when the first action has no time" do
    preparation = preparations(:opening_acts)
    preparation.actions.first.update!(start_time: nil)
    preparation.actions.last.update!(start_time: "07:00")
    preparation.update!(start_time: "09:35")

    assert_equal "09:35", preparation.reload.start_time
    assert_equal "09:35", preparation[:start_time]

    preparation.actions.first.update!(start_time: "09:30")

    assert_equal "09:30", preparation.reload.start_time
    assert_equal "09:35", preparation[:start_time]
  end

  test "derives unique commissions from its own action records" do
    preparation = preparations(:opening_acts)
    preparation.actions.first.update!(commissions: [ "EyA", "Programa" ])
    preparation.actions.last.update!(commissions: [ "Programa", "Hosp" ])

    assert_equal [ "EyA", "Programa", "Hosp" ], preparation.reload.commissions
  end

  test "does not delete a preparation with actions or delete those actions" do
    preparation = preparations(:opening_acts)

    assert_no_difference [ "Preparation.count", "Activity.count" ] do
      assert_not preparation.destroy
    end
    assert Preparation.exists?(preparation.id)
  end

  test "requires an existing preparation for action activities" do
    action = activities(:activity_48)
    action.preparation_id = 999

    assert_not action.valid?
    assert action.errors.of_kind?(:preparation, :blank)
  end
end

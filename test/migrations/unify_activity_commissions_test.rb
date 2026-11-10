require "test_helper"
require Rails.root.join("db/migrate/20261027000000_backfill_activity_details")
require Rails.root.join("db/migrate/20261028000000_unify_activity_commissions")

class UnifyActivityCommissionsTest < ActiveSupport::TestCase
  setup do
    ActivityDetail.delete_all
  end

  test "reconcile all reviewed commission labels without changing existing assignments or source wording" do
    UnifyActivityCommissions::COMMISSION_MAPPING.each_with_index do |(text, commissions), index|
      activity = Activity.create!(
        kind: "operation", title: "Commission case #{index}", day: "Domingo 15",
        source_id: Activity.maximum(:source_id) + 1, commissions: commissions,
        details: { "commission" => text }
      )
      detail = legacy_detail(activity, commission: text, notes: "Preserved notes")
      original_activity = activity.attributes
      original_detail = detail.attributes.except("commission", "updated_at")

      unify

      assert_equal original_activity, activity.reload.attributes
      assert_nil detail.reload.commission
      assert_equal original_detail, detail.attributes.except("commission", "updated_at")
    end
  end

  test "fill missing assignments from the explicit mapping for every activity kind" do
    [ activities(:opening_act), activities(:reception), activities(:chair_setup) ].each do |activity|
      activity.update!(commissions: [], details: { "commission" => "AC y Hosp" })
      legacy_detail(activity, commission: "AC y Hosp")
    end

    unify

    [ activities(:opening_act), activities(:reception), activities(:chair_setup) ].each do |activity|
      assert_equal [ "AC", "Hosp" ], activity.reload.commissions
      assert_equal "AC y Hosp", activity.details.fetch("commission")
      assert_nil legacy_detail(activity).commission
    end
  end

  test "recover an assignment present only in the migrated details" do
    activity = activities(:opening_act)
    activity.update!(commissions: [], details: {})
    legacy_detail(activity, commission: "Liturgia")

    unify

    assert_equal [ "Liturgia" ], activity.reload.commissions
    assert_nil legacy_detail(activity).commission
  end

  test "preserve the commission question in general questions without assigning commissions" do
    action = activities(:chair_setup)
    question = UnifyActivityCommissions::COMMISSION_QUESTION
    action.update!(commissions: [], details: { "commission" => question })
    detail = legacy_detail(action, commission: question, general_questions: "Existing question", executors: "Programme team")

    assert_no_difference "Question.count" do
      unify
    end

    assert_empty action.reload.commissions
    assert_equal "Existing question\n\n#{question}", detail.reload.general_questions
    assert_equal "Programme team", detail.executors
    assert_nil detail.commission
    assert_equal question, action.details.fetch("commission")
  end

  test "preserve a commission question even without an existing detail record" do
    action = activities(:chair_setup)
    question = UnifyActivityCommissions::COMMISSION_QUESTION
    action.update!(commissions: [], details: { "commission" => question })

    unify

    assert_equal question, action.reload.activity_detail.general_questions
    assert_empty action.commissions
  end

  test "leave empty assignments empty and do not infer commissions from executors" do
    action = activities(:chair_setup)
    action.update!(commissions: [], details: {})
    detail = legacy_detail(action, commission: " ", executors: "Programa y EyA")
    empty_act = activities(:opening_act)
    empty_act.update!(commissions: [], details: {})

    unify

    assert_empty action.reload.commissions
    assert_nil detail.reload.commission
    assert_equal "Programa y EyA", detail.executors
    assert_empty empty_act.reload.commissions
    assert_nil empty_act.activity_detail
  end

  test "retain an existing custom label without introducing a commission catalog" do
    activity = activities(:opening_act)
    activity.update!(commissions: [ "Local team" ], details: { "commission" => "Local team" })

    unify

    assert_equal [ "Local team" ], activity.reload.commissions
  end

  test "abort all changes when a source conflicts with the commission list" do
    activity = activities(:closing_act)
    activity.update!(details: { "commission" => "Programa" })
    detail = legacy_detail(activities(:opening_act), commission: "Programa")
    original = detail.attributes

    error = assert_raises(ActiveRecord::MigrationError) { unify }

    assert_includes error.message, "Activity #{activity.id}: commission text"
    assert_includes error.message, "conflicts with"
    assert_equal [ "Liturgia" ], activity.reload.commissions
    assert_equal original, detail.reload.attributes
  end

  test "abort when an edited detail disagrees with original wording" do
    activity = activities(:reception)
    detail = legacy_detail(activity, commission: "Programa")

    error = assert_raises(ActiveRecord::MigrationError) { unify }

    assert_includes error.message, "Activity #{activity.id}: commission text"
    assert_equal "Programa", detail.reload.commission
    assert_equal [ "Hosp" ], activity.reload.commissions
  end

  test "report unrecognized text without guessing assignments" do
    action = activities(:chair_setup)
    action.update!(commissions: [], details: { "commission" => "Programa o Liturgia?" })

    error = assert_raises(ActiveRecord::MigrationError) { unify }

    assert_includes error.message, "Activity #{action.id}: unrecognized commission text"
    assert_empty action.reload.commissions
    assert_nil action.activity_detail
  end

  test "reject malformed arrays and nontext commission values" do
    activity = activities(:opening_act)
    activity.update!(commissions: [ 123 ])
    action = activities(:chair_setup)
    action.update!(details: { "commission" => false })

    error = assert_raises(ActiveRecord::MigrationError) { unify }

    assert_includes error.message, "Activity #{activity.id}: commissions must be an array of nonblank strings"
    assert_includes error.message, "Activity #{action.id}: commission text must be a string"
  end

  test "rerunning preserves assignments and does not append the question twice" do
    action = activities(:chair_setup)
    question = UnifyActivityCommissions::COMMISSION_QUESTION
    action.update!(commissions: [], details: { "commission" => question })
    legacy_detail(action, commission: question, general_questions: "Existing question")
    unify
    original_activities = Activity.order(:id).map(&:attributes)
    original_details = UnifyActivityCommissions::ActivityDetailRecord.order(:id).map(&:attributes)

    unify

    assert_equal original_activities, Activity.order(:id).map(&:attributes)
    assert_equal original_details, UnifyActivityCommissions::ActivityDetailRecord.order(:id).map(&:attributes)
    assert_equal "Existing question\n\n#{question}", action.reload.activity_detail.general_questions
  end

  test "run after the original backfill without losing details or commission questions" do
    action = activities(:chair_setup)
    question = UnifyActivityCommissions::COMMISSION_QUESTION
    action.update!(commissions: [], details: {
      "commission" => question, "general_questions" => "Existing question", "notes" => "Keep these notes"
    })
    original = action.attributes
    backfill = BackfillActivityDetails.new
    backfill.suppress_messages { backfill.migrate(:up) }

    unify

    assert_equal original, action.reload.attributes
    assert_equal "Existing question\n\n#{question}", action.activity_detail.general_questions
    assert_equal "Keep these notes", action.activity_detail.notes
    assert_nil legacy_detail(action).commission
    assert_equal [ "Hosp" ], activities(:reception).reload.commissions
  end

  test "refuse a rollback that could overwrite later edits" do
    migration = UnifyActivityCommissions.new
    assert_raises(ActiveRecord::IrreversibleMigration) do
      migration.suppress_messages { migration.migrate(:down) }
    end
  end

  private

  def legacy_detail(activity, attributes = {})
    detail = UnifyActivityCommissions::ActivityDetailRecord.find_or_initialize_by(activity_id: activity.id)
    detail.update!(attributes) if attributes.any?
    detail
  end

  def unify
    migration = UnifyActivityCommissions.new
    migration.suppress_messages { migration.migrate(:up) }
  end
end

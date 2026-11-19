require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "find documents by their spreadsheet act" do
    spreadsheet = create_document(spreadsheet_act_key: "act-001")
    other = create_document(spreadsheet_act_key: "act-002")
    create_document(scope: "general")

    assert_equal [ spreadsheet ], Document.for_spreadsheet_act("act-001").to_a
    assert_equal [ spreadsheet, other ], Document.from_spreadsheet.order(:id).to_a
  end

  test "blank and unknown act references return empty chainable relations" do
    create_document(spreadsheet_act_key: "act-001")

    [ nil, "", " ", "unknown-act" ].each do |reference|
      assert_empty Document.for_spreadsheet_act(reference).with_attached_file.newest_first
    end
  end

  test "find unassigned spreadsheet documents without including general documents" do
    create_document(scope: "general")
    assigned = create_document(spreadsheet_act_key: "act-001")
    unassigned = create_document(spreadsheet_act_key: "act-002")

    assert_equal [ unassigned ], Document.without_spreadsheet_acts([ "act-001" ]).to_a
    assert_equal [ assigned, unassigned ], Document.without_spreadsheet_acts([]).order(:id).to_a
    assert_empty Document.without_spreadsheet_acts([ "act-001", "act-002" ])
  end

  test "order documents newest first with descending IDs to break timestamp ties" do
    older = create_document(spreadsheet_act_key: "act-001", created_at: Time.utc(2026, 11, 13))
    newer = create_document(spreadsheet_act_key: "act-001", created_at: Time.utc(2026, 11, 14))
    newest = create_document(spreadsheet_act_key: "act-001", created_at: newer.created_at)
    create_document(spreadsheet_act_key: "act-002", created_at: Time.utc(2026, 11, 15))

    assert_equal [ newest, newer, older ], Document.for_spreadsheet_act("act-001").newest_first.to_a
  end

  test "general documents are explicitly separate from act documents" do
    general = create_document(scope: "general")
    act = create_document(spreadsheet_act_key: "removed-act")

    assert general.scope_general?
    assert_nil general.spreadsheet_act_key
    assert act.scope_act?
    assert_equal [ general ], Document.scope_general.to_a
    assert_equal [ act ], Document.without_spreadsheet_acts([]).to_a
  end

  test "general documents reject an act reference" do
    document = Document.new(scope: "general", spreadsheet_act_key: "act-001")

    assert_not document.valid?
    assert document.errors[:spreadsheet_act_key].present?
  end

  test "enforce scope and nonblank act references in the database" do
    [
      {},
      { spreadsheet_act_key: "" },
      { spreadsheet_act_key: " " },
      { scope: "general", spreadsheet_act_key: "act-001" },
      { scope: "general", spreadsheet_act_key: "" },
      { scope: "unknown", spreadsheet_act_key: "act-001" }
    ].each do |attributes|
      assert_raises ActiveRecord::StatementInvalid do
        Document.insert_all!([ attributes ])
      end
    end
  end

  test "general documents require a file but not an act reference" do
    document = Document.new(scope: "general")

    assert_not document.valid?
    assert document.errors[:file].present?
    assert_empty document.errors[:spreadsheet_act_key]
  end

  test "reject unknown scopes" do
    document = Document.new(scope: "unknown")

    assert_not document.valid?
    assert document.errors[:scope].present?
  end

  test "act documents require an act reference" do
    document = Document.new(file: { io: StringIO.new("Instructions"), filename: "instructions.txt" })

    assert_not document.valid?
    assert document.errors.of_kind?(:spreadsheet_act_key, :blank)
    assert_empty document.errors[:file]
  end

  test "act documents require a file" do
    document = Document.new(spreadsheet_act_key: "act-001")

    assert_not document.valid?
    assert document.errors[:file].present?
    assert_empty document.errors[:spreadsheet_act_key]
  end

  test "label the file format" do
    { "instructions.pdf" => "PDF", "README" => "ARCHIVO" }.each do |filename, label|
      document = Document.new(file: { io: StringIO.new("Instructions"), filename: filename })

      assert_equal label, document.format_label
    end
  end

  private

  def create_document(**attributes)
    Document.create!(**attributes, file: { io: StringIO.new("Instructions"), filename: "instructions.txt" })
  end
end

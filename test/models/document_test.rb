require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "find documents by their legacy or spreadsheet act without mixing programs" do
    legacy = create_document(act_id: activities(:opening_act).id)
    create_document(act_id: activities(:closing_act).id)
    spreadsheet = create_document(spreadsheet_act_key: "act-001")
    other_spreadsheet = create_document(spreadsheet_act_key: "act-002")

    assert_equal [ legacy ], Document.for_legacy_act(activities(:opening_act).id).to_a
    assert_equal [ spreadsheet ], Document.for_spreadsheet_act("act-001").to_a
    assert_equal [ spreadsheet, other_spreadsheet ], Document.from_spreadsheet.order(:id).to_a
  end

  test "blank and unknown act references return empty chainable relations" do
    create_document(act_id: activities(:opening_act).id)
    create_document(spreadsheet_act_key: "act-001")

    [ nil, "", " " ].each do |reference|
      assert_empty Document.for_legacy_act(reference).with_attached_file.newest_first
      assert_empty Document.for_spreadsheet_act(reference).with_attached_file.newest_first
    end
    assert_empty Document.for_legacy_act(-1)
    assert_empty Document.for_spreadsheet_act("unknown-act")
  end

  test "find unassigned spreadsheet documents without including legacy documents" do
    create_document(act_id: activities(:opening_act).id)
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

  test "require an act reference" do
    document = Document.new(file: { io: StringIO.new("Instructions"), filename: "instructions.txt" })

    assert_not document.valid?
    assert document.errors.of_kind?(:act_id, :blank)
    assert_empty document.errors[:file]
  end

  test "require a file" do
    document = Document.new(act_id: activities(:opening_act).id)

    assert_not document.valid?
    assert document.errors[:file].present?
    assert_empty document.errors[:act_id]
  end

  test "allow spreadsheet documents without a legacy act reference" do
    document = Document.new(spreadsheet_act_key: "act-001", file: { io: StringIO.new("Layout"), filename: "layout.txt" })

    assert document.valid?
    assert_nil document.act_id
  end

  test "reject documents belonging to both programs" do
    document = Document.new(act_id: activities(:opening_act).id, spreadsheet_act_key: "act-001",
      file: { io: StringIO.new("Layout"), filename: "layout.txt" })

    assert_not document.valid?
    assert document.errors[:spreadsheet_act_key].present?
  end

  test "enforce exactly one nonblank reference in the database" do
    [ {}, { spreadsheet_act_key: " " }, { act_id: activities(:opening_act).id, spreadsheet_act_key: "act-001" } ].each do |attributes|
      assert_raises ActiveRecord::StatementInvalid do
        Document.insert_all!([ attributes ])
      end
    end
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

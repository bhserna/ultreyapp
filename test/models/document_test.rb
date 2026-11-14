require "test_helper"

class DocumentTest < ActiveSupport::TestCase
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
end

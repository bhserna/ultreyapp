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

  test "label the file format" do
    { "instructions.pdf" => "PDF", "README" => "ARCHIVO" }.each do |filename, label|
      document = Document.new(file: { io: StringIO.new("Instructions"), filename: filename })

      assert_equal label, document.format_label
    end
  end
end

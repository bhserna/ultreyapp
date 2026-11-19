class Document < ApplicationRecord
  has_one_attached :file

  enum :scope, { act: "act", general: "general" }, prefix: true, validate: true

  scope :for_spreadsheet_act, ->(key) { key.present? ? where(spreadsheet_act_key: key) : none }
  scope :from_spreadsheet, -> { where.not(spreadsheet_act_key: nil) }
  scope :without_spreadsheet_acts, ->(keys) { from_spreadsheet.where.not(spreadsheet_act_key: keys) }
  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  validates :spreadsheet_act_key, presence: true, if: :scope_act?
  validates :spreadsheet_act_key, absence: true, if: :scope_general?
  validate :file_attached

  def format_label
    file.filename.extension_without_delimiter.upcase.presence || "ARCHIVO"
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end

class Document < ApplicationRecord
  has_one_attached :file

  validates :act_id, presence: true, unless: -> { spreadsheet_act_key.present? }
  validates :spreadsheet_act_key, absence: true, if: -> { act_id.present? }
  validate :file_attached

  def format_label
    file.filename.extension_without_delimiter.upcase.presence || "ARCHIVO"
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end

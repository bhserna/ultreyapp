class Document < ApplicationRecord
  has_one_attached :file

  validates :schedule_entry_id, presence: true
  validate :file_attached

  def format_label
    file.filename.extension_without_delimiter.upcase.presence || "ARCHIVO"
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end

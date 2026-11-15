require "open-uri"

class SpreadsheetCopy < ApplicationRecord
  class DownloadError < StandardError; end

  MAX_FILE_SIZE = 20.megabytes
  CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

  has_one_attached :file

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  validate :file_attached

  def self.latest
    newest_first.first
  end

  def self.download!
    content = URI.open(Rails.configuration.x.spreadsheet_export_url, open_timeout: 10, read_timeout: 30) do |response|
      response.read(MAX_FILE_SIZE + 1).to_s
    end

    raise DownloadError, "The spreadsheet is too large" if content.bytesize > MAX_FILE_SIZE
    raise DownloadError, "The response is not an XLSX file" unless content.start_with?("PK\x03\x04".b)

    create!(file: {
      io: StringIO.new(content),
      filename: "program-#{Time.current.strftime('%Y%m%d-%H%M%S')}.xlsx",
      content_type: CONTENT_TYPE
    })
  rescue OpenURI::HTTPError, SocketError, Timeout::Error, IOError, SystemCallError, OpenSSL::SSL::SSLError => error
    raise DownloadError, error.message
  end

  def program
    @program ||= Program.new(Reader.new(self).read)
  end

  private

  def file_attached
    errors.add(:file, "must be attached") unless file.attached?
  end
end

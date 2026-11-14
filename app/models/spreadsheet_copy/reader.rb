class SpreadsheetCopy::Reader
  class ReadError < StandardError; end

  def initialize(copy)
    @copy = copy
  end

  def read
    workbook = nil
    @copy.file.open do |file|
      workbook = Roo::Excelx.new(file.path)
      workbook.sheets.each_with_object({}) do |name, sheets|
        sheet = workbook.sheet(name)
        next unless sheet.last_row

        headers = sheet.row(1).map { |value| value.to_s.strip }
        sheets[name] = (2..sheet.last_row).filter_map do |row_number|
          row = sheet.row(row_number)
          next if row.all?(&:blank?)

          headers.each_with_index.each_with_object({}) do |(header, index), values|
            values[header] = row[index] unless header.empty?
          end
        end
      end
    end
  # Roo can also raise NoMethodError when workbook metadata is missing.
  rescue Zip::Error, Roo::FileNotFound, Nokogiri::XML::SyntaxError, ArgumentError, NoMethodError,
    IOError, Errno::ENOENT, ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError => error
    raise ReadError, error.message
  ensure
    workbook&.close
  end
end

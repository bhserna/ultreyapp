class SpreadsheetCopy::Program
  class ReadError < StandardError; end

  COLUMNS = { schedule: "Horario", number: "# Acto", title: "Actividad" }.freeze

  def initialize(copy)
    @copy = copy
  end

  def acts
    @acts ||= read
  end

  private

  def read
    workbook = nil
    @copy.file.open do |file|
      workbook = Roo::Excelx.new(file.path)
      program_sheet_found = false
      acts = workbook.sheets.each_with_object([]) do |name, result|
        sheet = workbook.sheet(name)
        next unless sheet.last_row

        headers = sheet.row(1).map { |value| value.to_s.strip }
        next unless COLUMNS.values.all? { |column| headers.include?(column) }

        program_sheet_found = true
        columns = COLUMNS.transform_values { |column| headers.index(column) }
        (2..sheet.last_row).each do |row_number|
          row = sheet.row(row_number)
          title = row[columns[:title]].to_s.strip
          next if title.empty?

          result << SpreadsheetCopy::Act.new(
            day: name,
            schedule: row[columns[:schedule]].to_s.strip,
            number: row[columns[:number]],
            title: title
          )
        end
      end

      raise ReadError, "No program sheets found" unless program_sheet_found

      acts
    end
  # Roo can also raise NoMethodError when workbook metadata is missing.
  rescue Zip::Error, Roo::FileNotFound, Nokogiri::XML::SyntaxError, ArgumentError, NoMethodError,
    IOError, Errno::ENOENT, ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError => error
    raise ReadError, error.message
  ensure
    workbook&.close
  end
end

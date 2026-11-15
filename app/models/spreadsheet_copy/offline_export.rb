require "zip"

class SpreadsheetCopy::OfflineExport
  STYLESHEETS = %w[application base page link tabs toolbar table_container table schedule
    text_nowrap related_links documents site_nav offline utilities].freeze

  attr_reader :spreadsheet_copy, :program, :generated_at, :general_documents

  def initialize(spreadsheet_copy)
    @spreadsheet_copy = spreadsheet_copy
    @program = spreadsheet_copy.program
    @generated_at = Time.current
  end

  def write_to(path)
    @documents = Document.for_spreadsheet_act(program.document_keys)
      .with_attached_file.newest_first.to_a.group_by(&:spreadsheet_act_key)

    @general_documents = Document.scope_general.with_attached_file.newest_first.to_a

    Zip::OutputStream.open(path) do |zip|
      write_page(zip, "index.html", "index")
      write_page(zip, "general-documents.html", "general_documents")
      program.days.each do |day|
        entries = program.entries(day: day)
        write_page(zip, day_path(day), "day", day: day, entries: entries)
        entries.each do |entry|
          write_page(zip, entry_path(entry), "entry", entry: entry)
        end
      end
      write_styles(zip)
      write_documents(zip)
    end
  end

  def day_path(day)
    "day-#{program.days.index(day) + 1}.html"
  end

  def entry_path(entry)
    type = case entry
    when SpreadsheetCopy::Preparation then "preparation"
    when SpreadsheetCopy::PriorActivity then "prior-activity"
    else "act"
    end
    "#{day_path(entry.day).delete_suffix('.html')}-#{type}-#{entry.to_param}.html"
  end

  def document_path(document)
    filename = document.file.filename.to_s.gsub(/[^a-zA-Z0-9._-]/, "_")
    "documents/#{document.id}-#{filename}"
  end

  def documents_for(entry)
    return [] unless entry.is_a?(SpreadsheetCopy::Act)

    @documents.fetch(program.document_key_for(entry), [])
  end

  private

  def write_page(zip, path, template, **locals)
    zip.put_next_entry(path)
    zip.write ApplicationController.render(
      template: "offline_exports/#{template}", layout: "offline",
      locals: { export: self, **locals }
    )
  end

  def write_styles(zip)
    zip.put_next_entry("assets/application.css")
    STYLESHEETS.each do |name|
      zip.write Rails.root.join("app/assets/stylesheets/#{name}.css").read
      zip.write "\n"
    end
  end

  def write_documents(zip)
    (@documents.values.flatten + general_documents).each do |document|
      zip.put_next_entry(document_path(document))
      document.file.blob.download { |chunk| zip.write(chunk) }
    end
  end
end

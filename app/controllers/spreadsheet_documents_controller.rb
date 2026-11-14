class SpreadsheetDocumentsController < ApplicationController
  def index
    @spreadsheet_copy = SpreadsheetCopy.order(created_at: :desc, id: :desc).first
    keys = @spreadsheet_copy ? @spreadsheet_copy.program.document_keys : []
    @documents = Document.without_spreadsheet_acts(keys).with_attached_file.newest_first
  rescue SpreadsheetCopy::Reader::ReadError, SpreadsheetCopy::Program::ReadError
    @read_error = true
    flash.now[:alert] = "No se pudieron comprobar los documentos porque la copia más reciente no se puede leer. Los archivos siguen guardados."
  end
end

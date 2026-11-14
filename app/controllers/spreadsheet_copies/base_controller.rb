class SpreadsheetCopies::BaseController < ApplicationController
  before_action :set_spreadsheet_copy

  rescue_from SpreadsheetCopy::Reader::ReadError, SpreadsheetCopy::Program::ReadError, with: :show_read_error

  private

  def set_spreadsheet_copy
    @spreadsheet_copy = SpreadsheetCopy.find(params[:spreadsheet_copy_id])
  end

  def show_read_error(error)
    Rails.logger.warn("Spreadsheet program could not be read: #{error.class}")
    flash.now[:alert] = "No se pudo mostrar el programa de esta copia. El archivo guardado sigue disponible en Copias del spreadsheet."
    render "spreadsheet_copies/program_error"
  end
end

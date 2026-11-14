class SpreadsheetCopiesController < ApplicationController
  def index
    @spreadsheet_copies = SpreadsheetCopy.with_attached_file.order(created_at: :desc, id: :desc)
  end

  def create
    SpreadsheetCopy.download!
    redirect_to spreadsheet_copies_path, notice: "La copia del spreadsheet se guardó correctamente.", status: :see_other
  rescue SpreadsheetCopy::DownloadError => error
    Rails.logger.warn("Spreadsheet download failed: #{error.class}")
    redirect_to spreadsheet_copies_path, alert: "No se pudo descargar el spreadsheet. Intenta de nuevo; las copias anteriores siguen disponibles.", status: :see_other
  end
end

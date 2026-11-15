require "tempfile"

class SpreadsheetCopies::OfflineDownloadsController < SpreadsheetCopies::BaseController
  include ActionController::Live

  def show
    Tempfile.create([ "ultreyapp-offline-", ".zip" ]) do |file|
      @spreadsheet_copy.offline_export.write_to(file.path)
      file.rewind
      send_stream(filename: "ultreyapp-#{@spreadsheet_copy.id}-offline.zip", type: "application/zip") do |stream|
        IO.copy_stream(file, stream)
      end
    end
  rescue ActiveStorage::FileNotFoundError
    redirect_to spreadsheet_copy_program_path(@spreadsheet_copy),
      alert: "No se pudo generar la copia sin conexión porque falta un documento adjunto. No se descargó un ZIP incompleto."
  end
end

class SpreadsheetProgramsController < ApplicationController
  def show
    @spreadsheet_copy = SpreadsheetCopy.order(created_at: :desc, id: :desc).first
    return unless @spreadsheet_copy

    acts = @spreadsheet_copy.program.acts
    @days = acts.map(&:day).uniq
    @selected_day = @days.include?(params[:day]) ? params[:day] : @days.first
    @acts = acts.select { |act| act.day == @selected_day }
  rescue SpreadsheetCopy::Program::ReadError => error
    Rails.logger.warn("Spreadsheet program could not be read: #{error.class}")
    flash.now[:alert] = "No se pudo mostrar el programa de esta copia. El archivo guardado sigue disponible en Copias del spreadsheet."
  end
end

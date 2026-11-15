class CurrentProgramsController < ApplicationController
  def show
    copy = SpreadsheetCopy.latest

    if copy
      redirect_to spreadsheet_copy_program_path(copy)
    else
      redirect_to spreadsheet_copies_path, notice: "Todavía no hay copias del spreadsheet. Descarga una copia para ver el programa."
    end
  end
end

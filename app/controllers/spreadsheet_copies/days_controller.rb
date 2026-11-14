class SpreadsheetCopies::DaysController < SpreadsheetCopies::BaseController
  def show
    program = @spreadsheet_copy.program
    @days = program.days
    @selected_day = params[:id]
    raise ActiveRecord::RecordNotFound unless @days.include?(@selected_day)

    @entries = program.entries(day: @selected_day)
  end
end

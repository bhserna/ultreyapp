class SpreadsheetCopies::ProgramsController < SpreadsheetCopies::BaseController
  def show
    day = @spreadsheet_copy.program.days.first
    raise SpreadsheetCopy::Program::ReadError, "No activities found" unless day

    redirect_to spreadsheet_copy_day_path(@spreadsheet_copy, day)
  end
end

class SpreadsheetCopies::ProgramsController < SpreadsheetCopies::BaseController
  def show
    day = @spreadsheet_copy.program.acts.first&.day
    raise SpreadsheetCopy::Program::ReadError, "No activities found" unless day

    redirect_to spreadsheet_copy_day_path(@spreadsheet_copy, day)
  end
end

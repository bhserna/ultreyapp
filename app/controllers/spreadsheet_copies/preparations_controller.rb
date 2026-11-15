class SpreadsheetCopies::PreparationsController < SpreadsheetCopies::BaseController
  def show
    program = @spreadsheet_copy.program
    @preparation = program.find_preparation!(day: params[:day_id], id: params[:id])

    @related_acts = program.acts_for(@preparation)
    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
  end
end

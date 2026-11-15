class SpreadsheetCopies::PriorActivitiesController < SpreadsheetCopies::BaseController
  def show
    @prior_activity = @spreadsheet_copy.program.find_prior_activity!(day: params[:day_id], id: params[:id])
    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
  end
end

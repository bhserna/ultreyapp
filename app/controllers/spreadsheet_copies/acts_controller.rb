class SpreadsheetCopies::ActsController < SpreadsheetCopies::BaseController
  def show
    @act = @spreadsheet_copy.program.find_act!(day: params[:day_id], id: params[:id])

    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
  end
end

class SpreadsheetCopies::ActsController < SpreadsheetCopies::BaseController
  def show
    @act = @spreadsheet_copy.program.acts.find do |act|
      act.day == params[:day_id] && act.to_param == params[:id]
    end
    raise ActiveRecord::RecordNotFound unless @act

    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
  end
end

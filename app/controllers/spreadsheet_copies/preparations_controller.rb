class SpreadsheetCopies::PreparationsController < SpreadsheetCopies::BaseController
  def show
    program = @spreadsheet_copy.program
    @preparation = program.preparations.find do |preparation|
      preparation.day == params[:day_id] && preparation.to_param == params[:id]
    end
    raise ActiveRecord::RecordNotFound unless @preparation

    @related_acts = program.acts_for(@preparation)
    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
  end
end

class SpreadsheetCopies::DaysController < SpreadsheetCopies::BaseController
  def show
    program = @spreadsheet_copy.program
    @days = program.days
    @selected_day = params[:id]
    raise ActiveRecord::RecordNotFound unless @days.include?(@selected_day)

    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
    @entries = program.entries(day: @selected_day, row_type: @selected_row_type)
    @document_counts = Document.from_spreadsheet.where(spreadsheet_act_key: program.document_keys)
      .group(:spreadsheet_act_key).count
  end
end

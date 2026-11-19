class SpreadsheetCopies::PrintoutsController < SpreadsheetCopies::BaseController
  def show
    program = @spreadsheet_copy.program
    @days = program.days
    @selected_day = params[:day].presence
    raise ActiveRecord::RecordNotFound if @selected_day && !@days.include?(@selected_day)

    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
    @include_details = params[:include_details] != "0"
    selected_days = @selected_day ? [ @selected_day ] : @days
    @entries_by_day = selected_days.index_with do |day|
      program.entries(day: day, row_type: @selected_row_type)
    end
  end
end

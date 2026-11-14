class SpreadsheetCopies::DaysController < SpreadsheetCopies::BaseController
  def show
    acts = @spreadsheet_copy.program.acts
    @days = acts.map(&:day).uniq
    @selected_day = params[:id]
    raise ActiveRecord::RecordNotFound unless @days.include?(@selected_day)

    @acts = acts.select { |act| act.day == @selected_day }
  end
end

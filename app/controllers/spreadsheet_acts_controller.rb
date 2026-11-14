class SpreadsheetActsController < ApplicationController
  def show
    @spreadsheet_copy = SpreadsheetCopy.find(params[:spreadsheet_copy_id])
    @act = @spreadsheet_copy.program.acts.find do |act|
      act.day == params[:day] && act.position.to_s == params[:id]
    end
    raise ActiveRecord::RecordNotFound unless @act
  rescue SpreadsheetCopy::Reader::ReadError, SpreadsheetCopy::Program::ReadError
    redirect_to spreadsheet_program_path(copy_id: @spreadsheet_copy.id, day: params[:day])
  end
end

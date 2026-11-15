class SpreadsheetCopies::DocumentsController < SpreadsheetCopies::BaseController
  before_action :set_act

  def index
    @documents = documents_for_act.with_attached_file.newest_first
  end

  def create
    raise ActiveRecord::RecordNotFound unless @document_key

    files = Array(params.require(:files)).reject(&:blank?)
    Document.transaction do
      files.each do |file|
        Document.create!(spreadsheet_act_key: @document_key, spreadsheet_act_title: @act.title, file: file)
      end
    end
    redirect_to documents_path, status: :see_other
  end

  def destroy
    raise ActiveRecord::RecordNotFound unless @document_key

    document = documents_for_act.find(params[:id])
    document.file.purge
    document.destroy!
    redirect_to documents_path, status: :see_other
  end

  private

  def set_act
    program = @spreadsheet_copy.program
    @act = program.find_act!(day: params[:day_id], id: params[:act_id])

    @document_key = program.document_key_for(@act)
    @selected_row_type = params[:row_type].presence_in(SpreadsheetCopy::Program::ROW_TYPES)
    @unavailable_message = if @act.source_key.blank?
      "Este acto no tiene ID en el spreadsheet. Agrega un ID estable y descarga una nueva copia para adjuntar documentos."
    elsif @document_key.nil?
      "El ID de este acto está duplicado en el spreadsheet. Corrígelo y descarga una nueva copia para consultar o adjuntar documentos."
    end
  end

  def documents_for_act
    Document.for_spreadsheet_act(@document_key)
  end

  def documents_path
    spreadsheet_copy_day_act_documents_path(@spreadsheet_copy, @act.day, @act, row_type: @selected_row_type)
  end
end

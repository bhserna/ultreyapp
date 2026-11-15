class GeneralDocumentsController < ApplicationController
  def index
    @documents = Document.scope_general.with_attached_file.newest_first
  end

  def create
    files = Array(params.require(:files)).reject(&:blank?)

    Document.transaction do
      files.each do |file|
        Document.scope_general.create!(file: file)
      end
    end

    redirect_to general_documents_path, status: :see_other
  end

  def destroy
    document = Document.scope_general.find(params[:id])
    document.file.purge
    document.destroy!
    redirect_to general_documents_path, status: :see_other
  end
end

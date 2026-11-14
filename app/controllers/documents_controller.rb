class DocumentsController < ApplicationController
  before_action :set_activity

  def index
    @documents = documents_for_activity.with_attached_file.newest_first
  end

  def create
    uploaded_files = Array(params.require(:files)).reject(&:blank?)

    Document.transaction do
      uploaded_files.each do |uploaded_file|
        Document.create!(act_id: @activity.id, file: uploaded_file)
      end
    end

    redirect_to schedule_entry_documents_path(@activity.id), status: :see_other
  end

  def destroy
    document = documents_for_activity.find(params[:id])
    document.file.purge
    document.destroy!
    redirect_to schedule_entry_documents_path(@activity.id), status: :see_other
  end

  private

  def set_activity
    @activity = Activity.acts.find(params[:schedule_entry_id])
  end

  def documents_for_activity
    Document.for_legacy_act(@activity.id)
  end
end

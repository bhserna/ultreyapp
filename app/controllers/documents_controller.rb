class DocumentsController < ApplicationController
  before_action :set_schedule_entry

  def index
    @documents = documents_for_entry.with_attached_file.order(created_at: :desc, id: :desc)
  end

  def create
    uploaded_files = Array(params.require(:files)).reject(&:blank?)

    Document.transaction do
      uploaded_files.each do |uploaded_file|
        Document.create!(schedule_entry_id: @schedule_entry.id, file: uploaded_file)
      end
    end

    redirect_to schedule_entry_documents_path(@schedule_entry.id), status: :see_other
  end

  def destroy
    document = documents_for_entry.find(params[:id])
    document.file.purge
    document.destroy!
    redirect_to schedule_entry_documents_path(@schedule_entry.id), status: :see_other
  end

  private

  def set_schedule_entry
    @schedule_entry = ScheduleEntry.find(params[:schedule_entry_id])
  end

  def documents_for_entry
    Document.where(schedule_entry_id: @schedule_entry.id)
  end
end

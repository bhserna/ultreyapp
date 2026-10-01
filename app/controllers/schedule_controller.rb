class ScheduleController < ApplicationController
  def index
    @schedule_entries = YAML.safe_load_file(Rails.root.join("config/schedule.yml"))
  end
end

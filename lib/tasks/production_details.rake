namespace :production_details do
  desc "Create or update production details from config/data/production_details.yml"
  task import: :environment do
    path = ENV.fetch("PRODUCTION_DETAILS_FILE", Rails.root.join("config/data/production_details.yml").to_s)
    source = YAML.safe_load_file(path)
    entries = source.fetch("production_details")

    ProductionDetail.transaction do
      entries.each do |entry|
        schedule_entry = ScheduleEntry.find(entry.fetch("schedule_entry_id"))
        unless schedule_entry.activity == entry.fetch("activity")
          raise ArgumentError, "Activity does not match schedule entry #{schedule_entry.id}"
        end

        attributes = entry.fetch("attributes").slice(*%w[
          executors screen audio room_lighting stage_lighting aisle_lighting
          requirements notes radios pending_confirmations
        ])
        detail = ProductionDetail.find_or_initialize_by(schedule_entry_id: schedule_entry.id)
        detail.update!(attributes)
      end
    end

    puts "Imported #{entries.size} production details."
  end
end

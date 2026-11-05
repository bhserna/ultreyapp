namespace :activities do
  desc "Import missing activities from YAML without overwriting existing records"
  task import: :environment do
    Activity.import_from_source!
    puts "Activities imported; existing records were left unchanged."
  end
end

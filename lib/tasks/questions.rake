namespace :questions do
  desc "Replace all questions and topics with those in config/follow_up_questions.yml"
  task import: :environment do
    path = ENV.fetch("QUESTIONS_FILE", Rails.root.join("config/follow_up_questions.yml").to_s)
    source = YAML.safe_load_file(path)

    ActiveRecord::Base.transaction do
      Question.delete_all
      Topic.delete_all

      source.fetch("schedule_entries").each do |entry|
        schedule_entry_id = entry.fetch("id")
        ScheduleEntry.find(schedule_entry_id)

        entry.fetch("questions").each do |item|
          Question.create!(schedule_entry_id: schedule_entry_id, body: item.fetch("question"), answer: item["answer"])
        end
      end

      %w[cross_cutting_questions general_questions].each do |section|
        source.fetch(section).each do |entry|
          topic = Topic.create!(name: entry.fetch("topic"))

          entry.fetch("questions").each do |item|
            Question.create!(topic: topic, body: item.fetch("question"), answer: item["answer"])
          end
        end
      end
    end

    puts "Imported #{Question.count} questions and #{Topic.count} topics."
  end
end

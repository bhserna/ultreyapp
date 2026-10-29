namespace :data_updates do
  desc "Preview the rosary executors update; pass [apply] to save it"
  task :rosary_executors, [ :mode ] => :environment do |_task, args|
    mode = args[:mode] || "preview"
    unless %w[preview apply].include?(mode)
      raise ArgumentError, "Use data_updates:rosary_executors[preview] or [apply]"
    end

    previous = "Yola y Beba / 5 sacerdotes / Jeseed"
    replacement = "Yola y Beba / Laicos y 5 sacerdotes / Jeseed"
    entry = ScheduleEntry.find(22)
    raise "Expected schedule entry 22 to be Rosario (act 19)" unless entry.activity == "Rosario" && entry.act_number.to_s == "19"

    ProductionDetail.transaction do
      detail = ProductionDetail.find_by!(schedule_entry_id: 22)

      if detail.executors == replacement
        puts "Already updated: Rosario (schedule_entry_id=22). No changes."
      elsif detail.executors != previous
        raise "Conflict: Rosario executors are #{detail.executors.inspect}; expected #{previous.inspect}. No changes."
      else
        puts "Rosario (schedule_entry_id=22), executors: #{previous.inspect} -> #{replacement.inspect}"
        if mode == "apply"
          # Compare and write atomically so concurrent manual edits are never overwritten.
          updated = ProductionDetail.where(id: detail.id, executors: previous)
            .update_all(executors: replacement, updated_at: Time.current)
          raise "Conflict: Rosario changed during the update. No changes." unless updated == 1

          puts "Updated 1 record."
        else
          puts "Preview only. No changes. Pass [apply] to save."
        end
      end
    end
  end
end

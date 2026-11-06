module ActivityDetailsHelper
  def activity_detail_attributes(activity)
    activity.details.merge(
      activity.production_detail.to_h.stringify_keys,
      "executors" => activity.executors,
      "notes" => activity.notes,
      "pending_confirmations" => activity.pending_confirmations
    )
  end
end

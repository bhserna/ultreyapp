module ActivityDetailsHelper
  def activity_detail_fields
    {
      description: "Descripción",
      executors: "Ejecuta",
      screen: "Pantalla",
      audio: "Audio",
      room_lighting: "Iluminación de sala",
      stage_lighting: "Iluminación de escenario",
      aisle_lighting: "Iluminación de pasillos",
      requirements: "Requerimientos",
      arena_questions: "Preguntas para la Arena",
      general_questions: "Dudas generales",
      notes: "Notas",
      media_files: "Videos o pistas",
      radios: "Radios",
      pending_confirmations: "Pendientes por confirmar"
    }
  end

  def activity_return_path(activity)
    case activity.kind
    when "act"
      schedule_entry_path(activity)
    when "operation"
      operational_activity_path(activity.source_id)
    when "preparation_action"
      preparation_path(activity.preparation_id, anchor: dom_id(activity))
    end
  end
end

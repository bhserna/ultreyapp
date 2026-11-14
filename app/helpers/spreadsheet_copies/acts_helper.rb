module SpreadsheetCopies::ActsHelper
  def spreadsheet_act_detail_fields
    {
      audio: "Audio",
      screen: "Video / Pantalla",
      ring: "Anillo",
      lighting: "Iluminación",
      special_effects: "Efectos especiales",
      pending_files: "Archivos pendientes",
      ready_files: "Archivos listos"
    }
  end
end

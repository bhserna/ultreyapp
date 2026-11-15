module SpreadsheetCopies::EntriesHelper
  def spreadsheet_program_entry_path(copy, entry, row_type: nil)
    case entry
    when SpreadsheetCopy::Preparation
      spreadsheet_copy_day_preparation_path(copy, entry.day, entry, row_type: row_type)
    when SpreadsheetCopy::PriorActivity
      spreadsheet_copy_day_prior_activity_path(copy, entry.day, entry, row_type: row_type)
    else
      spreadsheet_copy_day_act_path(copy, entry.day, entry, row_type: row_type)
    end
  end

  def spreadsheet_entry_type(entry)
    case entry
    when SpreadsheetCopy::Preparation then "Preparación"
    when SpreadsheetCopy::PriorActivity then "Actividad previa"
    else "Acto"
    end
  end

  def spreadsheet_entry_number(entry)
    case entry
    when SpreadsheetCopy::Preparation then entry.act_number
    when SpreadsheetCopy::Act then entry.number
    end
  end

  def spreadsheet_entry_detail_fields(entry)
    case entry
    when SpreadsheetCopy::Preparation then spreadsheet_preparation_detail_fields
    when SpreadsheetCopy::PriorActivity then spreadsheet_prior_activity_detail_fields
    else spreadsheet_act_detail_fields
    end
  end
end

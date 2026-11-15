module SpreadsheetCopies::PrintoutsHelper
  def printout_entry_type(entry)
    case entry
    when SpreadsheetCopy::Preparation then "Preparación"
    when SpreadsheetCopy::PriorActivity then "Actividad previa"
    else "Acto"
    end
  end

  def printout_entry_number(entry)
    case entry
    when SpreadsheetCopy::Preparation then entry.act_number
    when SpreadsheetCopy::Act then entry.number
    end
  end

  def printout_detail_fields(entry)
    case entry
    when SpreadsheetCopy::Preparation then spreadsheet_preparation_detail_fields
    when SpreadsheetCopy::PriorActivity then spreadsheet_prior_activity_detail_fields
    else spreadsheet_act_detail_fields
    end
  end
end

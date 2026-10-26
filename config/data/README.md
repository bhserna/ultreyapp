# Event data

The active files are `schedule.yml`, `questions.yml`, and `production_details.yml`. They are based on the first sheet of:

https://docs.google.com/spreadsheets/d/1EmpnzOyj9OpEx48-1GhAy5Gym5kUjlMs/edit?gid=1593648280

## Current version

- Include only rows with an act number and a yellow Act cell, verified in the XLSX export (the CSV does not retain colors).
- Blue preparation rows, beige extra activities, and unnumbered rows are excluded for now.
- There are 31 entries: acts 1–28, with act 7 represented by subacts `7.1`–`7.4`. Act 28 (teardown) has a yellow Act cell and is included.
- IDs are consecutive in spreadsheet row order. `source_row` / `source_rows` count the header as row 1.
- Times are normalized to 24-hour format. Missing times and durations are not inferred; source wording is preserved.
- `questions.yml` contains only the 12 questions directly on these act rows. Questions from preparation or extra-activity rows are not assigned to acts. The previous complete question extraction remains in `previous/questions.yml`.

## Production details

`production_details.yml` contains the ten production fields for the current numbered acts, linked by `schedule_entry_id`. It preserves source wording and line breaks, with blank cells represented as `null`. It excludes preparation, extra activities, questions, and the media-files column. Acts with all ten fields empty are omitted (18 acts currently have production data).

The spreadsheet has changed since the schedule extraction: rows have moved, and some acts are repeated later with their production information filled in. Entries were matched by act number and activity, not the old row number. `source_row` records the row supplying the production data in the latest extraction.

```sh
bin/rails production_details:import
```

The task creates missing details and updates existing ones for the listed acts, without duplicates. All ten fields are replaced by their YAML values, including clearing fields whose value is `null`. Manual edits to these fields will therefore be overwritten. Details for acts not listed in the YAML, questions, and documents are left unchanged. The import runs in a transaction and rejects unknown IDs or activity names that do not match the current schedule.

To use a different file:

```sh
PRODUCTION_DETAILS_FILE=path/to/production_details.yml bin/rails production_details:import
```

## Previous version

`previous/` contains the unchanged `schedule.yml`, `questions.yml`, and `old_follow_up_questions.yml` from before regeneration. Its IDs belong to the previous schedule, not the active one.

## Importing questions

```sh
bin/rails questions:import
```

This replaces all questions and topics using the active `questions.yml`. The schedule itself is read directly from YAML.

**The new IDs are not compatible with existing database references.** Regenerating these files does not migrate or delete existing questions, documents, or production details. Importing questions replaces the questions and topics only. Before using the new schedule with existing documents or production details, reconcile their `schedule_entry_id` values using the previous schedule; otherwise they may appear under a different activity. Do not import the archived question files against the new schedule.

# Event data

The active files are `schedule.yml`, `questions.yml`, `production_details.yml`, and `preparations.yml`. They are based on the first sheet of:

https://docs.google.com/spreadsheets/d/1EmpnzOyj9OpEx48-1GhAy5Gym5kUjlMs/edit?gid=1593648280

## Current version

- Include only rows with an act number and a yellow Act cell, verified in the XLSX export (the CSV does not retain colors). Stop at the end of the Monday 16 block, currently row 111 (teardown); exclude any later scratch blocks.
- Blue preparation rows, beige extra activities, and unnumbered rows are excluded for now.
- There are 31 entries: acts 1–28, with act 7 represented by subacts `7.1`–`7.4`. Act 28 (teardown) has a yellow Act cell and is included.
- IDs are preserved by act number when updating the source, even if titles, times, or row positions change. `source_row` / `source_rows` count the header as row 1.
- Times are normalized to 24-hour format. Missing times and durations are not inferred; source wording is preserved.
- `questions.yml` contains the 24 questions directly on these act rows, including the questions in the final notices' Notes cell. Questions from preparation or extra-activity rows are not assigned to acts. The previous complete question extraction remains in `previous/questions.yml`.

## Preparations

`preparations.yml` stores 17 dark-blue preparation headers and 23 light-blue action rows, stopping at the end of Monday 16. It is read directly by the app; no database import is needed. The program table interleaves acts and preparation summaries by start time, with blue preparation rows. Each preparation's start time is taken from its first action; if that action has no start time, the header time is retained. Undecided times remain text and sort last. This corrects the act 7 preparation to `12:30` instead of the header's `00:15`. Day and commission filters apply to both kinds of rows, using each preparation's own day and action commissions. Shared preparations appear only once in the table. Each preparation row links to its own detail page with action timings, responsibilities, technical information, questions, notes, material references, and links to related acts. Preparation content is not displayed on act detail pages. Orange conclusions are excluded, as is row 38 (times without an action description).

- `schedule_entry_ids` supports shared preparations: acts 1 and 2 share a block; the act 7 block is shown for subacts 7.1–7.4.
- The general pre-parade block has no act reference; it appears in the program and has its own detail page.
- Original header text remains in `source_title`; action timings and durations are preserved. The preparation's start time follows its first action rather than an inconsistent header.
- `source_title` and source rows preserve provenance. The Tema 2 block is linked to act 13 despite the source heading saying act 11. The heading for act 17 is displayed as Monday 16, correcting the source's Sunday 16; the actual preparation takes place on Sunday 15 at 19:00.
- Action descriptions retain their multiline lists. Questions and material references remain within the preparation and are not imported as act questions or documents.

## Production details

`production_details.yml` contains the ten production fields for the current numbered acts, linked by `schedule_entry_id`. It preserves source wording and line breaks, with blank cells represented as `null`. It excludes preparation, extra activities, questions, and the media-files column. Acts with all ten fields empty are omitted (19 acts currently have production data).

The three active YAML files use the same current source rows. No production data is taken from repeated acts or preparation blocks outside the selected range. The current Monday acts have no production content; no details are imported for them. An older detail omitted from the new YAML is not deleted by the import task, so previously imported content for those acts must be reviewed separately.

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

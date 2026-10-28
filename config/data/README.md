# Event data

The active files are `schedule.yml`, `questions.yml`, `production_details.yml`, `preparations.yml`, and `operational_activities.yml`. They are based on the two main program sheets (`1er, día 15 Nov` and `2do. día 16 Nov`) of:

https://docs.google.com/spreadsheets/d/1EmpnzOyj9OpEx48-1GhAy5Gym5kUjlMs/edit?gid=1593648280

## Current version

- Include only rows with an act number and a yellow Act cell, verified in the XLSX export (the CSV does not retain colors). The source now separates Sunday and Monday into the two main sheets. Stop at Monday's teardown, row 40 of `2do. día 16 Nov`; exclude all team working sheets and scratch blocks.
- Blue preparations are stored separately in `preparations.yml`. Beige extra activities and unnumbered rows are not acts.
- There are 31 entries: acts 1–28, with act 7 represented by subacts `7.1`–`7.4`. Act 28 (teardown) has a yellow Act cell and is included.
- IDs are preserved by act number when updating the source, even if titles, times, or row positions change. `source_sheet` identifies the worksheet; `source_row` / `source_rows` count each sheet's header as row 1.
- Times are normalized to 24-hour format. Missing times and durations are not inferred; source wording is preserved.
- `questions.yml` contains the 36 questions directly on these act rows, including the questions in the final notices' Notes cell. Questions from preparation or extra-activity rows are not assigned to acts. The previous complete question extraction remains in `previous/questions.yml`.

## Preparations

`preparations.yml` stores 26 dark-blue preparation headers and 32 light-blue action rows, stopping at the end of Monday 16. It is read directly by the app; no database import is needed. The program table groups rows by phase and interleaves acts and preparation summaries by start time within the program phase, with blue preparation rows. Each preparation's start time is taken from its first action; if that action has no start time, the header time is retained. Undecided times remain text and sort last within their phase when no end time is available. This corrects the act 7 preparation to `12:30` instead of the header's `00:15`. Day and commission filters apply to both kinds of rows, using each preparation's own day and action commissions. Shared preparations appear only once in the table. Each preparation row links to its own detail page with action timings, responsibilities, technical information, questions, notes, material references, and links to related acts. Preparation content is not displayed on act detail pages. Orange conclusions are excluded, as is Sunday row 38 (times without an action description). Existing preparation IDs 1–17 remain unchanged; the nine new Monday preparations use IDs 18–26.

- `schedule_entry_ids` supports shared preparations: acts 1 and 2 share a block; the act 7 block is shown for subacts 7.1–7.4.
- The general pre-parade block has no act reference; it appears in the program and has its own detail page.
- Original header text remains in `source_title`; action timings and durations are preserved. The preparation's start time follows its first action rather than an inconsistent header.
- `source_title` and source rows preserve provenance. The Tema 2 block is linked to act 13 despite the source heading saying act 11. The heading for act 17 is displayed as Monday 16, correcting the source's Sunday 16; the actual preparation takes place on Sunday 15 at 19:00.
- Monday's Vivencia 6 preparation links to act 24 despite its heading saying act 23; `source_title` retains the original. Other source inconsistencies are not silently corrected: the Vivencia 4 action starts at `21:30` although its heading says `09:30`, Vivencia 6's action starts at `11:05` although its heading says `11:30`, and the Tema 3 preparation names José Humberto Marroquín whereas the act names Pbro. Jose Juan Montalvo. Review these in the spreadsheet.
- Action descriptions retain their multiline lists. Questions and material references remain within the preparation and are not imported as act questions or documents.

## Operational activities

`operational_activities.yml` stores 13 activities before the first preparation in `1er, día 15 Nov`: rows 3–4 and 7–17. Row 18, “Se finalizan las actividades previas”, is deliberately excluded. Existing act and preparation IDs are unchanged; operations have their own IDs and `/operational_activities/:id` pages.

The four user-facing categories are reception and participant support, setup and installations, technical preparation, and services and vendors. Original titles, responsibilities, technical requirements, questions, notes, and radios are retained. Known times use 24-hour notation; blank and undecided times remain blank or retain their source wording. No missing durations are inferred. Source sheet and row identify each record.

The program adds Saturday 14 for reception and kits, and places Sunday operations in the pre-event block before preparations and acts. It still opens on Sunday, the first day with acts, by default. Operations have no act number and use a separate table style with their category. The type filter offers all rows, acts, preparations, or operations; day and commission filters combine with it, and day tabs and table commission links preserve the selected type. Undecided times sort after known times within their phase unless a known end time can be used for ordering. The program table displays a dash for missing or undecided times; detail pages retain the original wording, such as “Por definir con la Arena”. Operations with no commission remain visible without a commission filter.

Technical details reuse the preparation details partial. Operational questions remain on their own detail pages and are not imported as act questions. This file is read directly by the app: deployment is sufficient, with no database migration or import required.

## Program phases and ordering

Each row can specify `phase`, independently of its type, title, category, or source color. The default is `program`; the 13 current operations explicitly use `pre_event`, and preparation 1 explicitly uses `before_parade`. An operation during the program can use `program` without being placed in the pre-event block.

The table displays these phases in order, with headings only for nonempty groups after filtering:

1. `pre_event`: “Operación previa”.
2. `before_parade`: “Preparación previa al desfile”.
3. `program`: “Programa del día”.

Rows within each phase sort by known start time, then by known end time if the start is missing or undecided. If neither is known, the row stays at the end of its own phase rather than the end of the day. This places the sound and lighting test using its `08:00` end, keeps photographer and pyrotechnics preparation in the pre-event block, and places preparation 1 before the `09:45` preparation for acts 1 and 2. The Sunday `19:00` preparation for Monday remains at the end of Sunday's program. Sorting never fills in missing times: the table still shows “—” and details retain original source wording.

## Production details

`production_details.yml` contains the ten production fields for the current numbered acts, linked by `schedule_entry_id`. It preserves source wording and line breaks, with blank cells represented as `null`. It excludes preparation, extra activities, questions, and the media-files column. Acts with all ten fields empty are omitted (all 31 acts currently have production data).

The active YAML files identify their source sheets and rows consistently. No production data is taken from team working sheets or preparation blocks. Monday now includes production content for all its acts. An older detail omitted from a future YAML is not deleted by the import task, so previously imported content for omitted acts must be reviewed separately.

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

**The initial regeneration's IDs are not compatible with the archived schedule's database references.** Subsequent refreshes, including the split into two main sheets, preserve the active IDs. Regenerating these files does not migrate or delete existing questions, documents, or production details. Importing questions replaces the questions and topics only. Before using the new schedule with existing documents or production details, reconcile their `schedule_entry_id` values using the previous schedule; otherwise they may appear under a different activity. Do not import the archived question files against the new schedule.

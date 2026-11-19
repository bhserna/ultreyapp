# Retired program removal

Migration `20261115010000_remove_retired_program.rb` removes the database storage
for the program that preceded spreadsheet copies:

- `activity_details`
- `activities`
- `preparations`
- `questions` (including answers)
- `topics`
- `documents.act_id`

## Data preservation

Before making any schema changes, the migration writes all rows from the retired
tables and all documents with a legacy `act_id` into a JSON archive under
`storage/retired_program_backups/`. The filename is unique and printed in the
migration log. The archive records the original document-to-act references and
all original column values. JSON columns are exported as their raw database
values. Files are created with mode `0600`; treat them as sensitive data.

If every retired table is empty and there are no legacy documents, no archive is
needed. Otherwise, an archive write failure aborts the migration before changing
the database. Keep sufficient free disk space for both the export and SQLite's
table rebuilds. A failed migration can leave an archive behind; retrying creates
a new file rather than overwriting it.

Legacy documents become **general documents**. Their IDs, timestamps, Active
Storage attachments, blobs, and file contents are retained. Spreadsheet documents
and existing general documents are unchanged. No files are purged.

The JSON export is not a full database backup, does not include file bytes, and
has no automated import command. The migration is intentionally irreversible.

## Production deployment checklist

1. Stop writes during the backup and migration window. The preceding application
   version has already removed the retired routes, but documents can still change.
2. Follow [the backup guide](backups.md) to force a fresh database backup and
   verify that it can be read. Preserve this specific pre-migration snapshot
   outside normal retention. Back up Active Storage objects separately: the
   configured database backups do not include those objects.
3. Deploy with the new migration. Do not attempt to roll back to an application
   version that requires the removed tables against the migrated database.
4. Check the migration log and copy the generated JSON archive to secure,
   off-server storage. The current backup configuration has `paths: []`, so it
   does **not** automatically back up `storage/retired_program_backups/`.
5. Verify the current program, spreadsheet copies, general documents, act
   documents, printouts, and offline downloads. Confirm that former legacy
   documents are accessible in **Documentos generales**.
6. Resume writes after verification.

To recover the old program, restore the pre-migration database and corresponding
application version in an isolated environment first. A database restore after
resuming writes would discard newer changes, so reconcile those changes before
any production recovery. Never run a recovery drill against the live database.

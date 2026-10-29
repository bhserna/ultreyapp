# Production database backups

`kamal-backup` runs as a Kamal accessory on the app server. It uses SQLite's
native backup operation and sends encrypted Restic snapshots to the private
DigitalOcean Spaces Standard Storage bucket `ultreyapp-backups-standard` in `sfo3`.

New backups go to this bucket. Historical backups in the previous Cold Storage
bucket `ultreyapp-backups` are not migrated or deleted by this configuration.

## Coverage

- `production.sqlite3`: application data, including Active Storage metadata.
- `production_queue.sqlite3`: Solid Queue jobs.
- One backup run per hour. Each database retains the latest 24 snapshots,
  30 daily, 4 weekly, and 12 monthly snapshots.
- After each backup, check repository integrity and read a 5% data subset.
- Cache and Action Cable databases are not backed up; they can be rebuilt.
- **Objects in the `ultreyapp` Active Storage bucket are not backed up by this
  configuration.** They need a separate process with historical recovery.

The two SQLite databases are backed up separately, not as one atomic snapshot.
When recovering pending jobs, account for operations that may already have run.

Settings are in `config/kamal-backup.yml`; the container and mounts are in
`config/deploy.yml`. The app storage mount must be writable for live SQLite WAL
backups. The backup state volume preserves check and restore-drill evidence; it
is not the off-server backup repository.

## Credentials (one-time setup)

1. Keep the backup bucket private. Do not apply object expiration rules directly
   to Restic repository files; Restic manages retention and shared data itself.
2. The backup accessory reuses `spaces.access_key_id` and
   `spaces.secret_access_key` from Rails credentials, just like Active Storage.
   Confirm this key also has read, write, list, and delete access to
   `ultreyapp-backups-standard` (delete is required for retention).
3. Run `bin/rails credentials:edit` and add a strong, unique encryption password
   under `backups.restic_password`, preserving the existing credentials:

   ```yaml
   backups:
     restic_password: your-unique-strong-restic-password
   ```

   Save this password in a password manager, separate from the server.
   **Losing the Restic password makes the backups unusable.** Keep the Rails
   master key safe as well. Never paste real secrets into tracked plaintext
   files, chat, or shell commands saved in history.

No `.env.backup` file is required with this setup. `.kamal/secrets` reads the
values through `bin/rails credentials:fetch` on your local machine.

The backup accessory's Spaces variables are mapped to the `AWS_*` names
required by Restic's S3-compatible backend. These credentials are for
DigitalOcean, not AWS.

Kamal parses `.kamal/secrets` with Dotenv, not a full shell. Use simple
`$(bin/rails credentials:fetch ...)` substitutions; shell fallback expressions
such as `${VARIABLE:-$(...)}` are not supported by this setup.

Do not generate a new Restic password each time you deploy. If a repository
already exists, use its existing password.

## Start and verify

After setting up Rails credentials:

```sh
bundle exec kamal-backup validate
bin/kamal accessory boot backup
bundle exec kamal-backup backup --force
bundle exec kamal-backup list
bundle exec kamal-backup check
bundle exec kamal-backup evidence
```

`validate` checks configuration and missing secrets; it does not establish that
the credentials can access Spaces. The first backup initializes the repository
if it is missing. Inspect logs if any command fails:

```sh
bin/kamal accessory logs backup
```

The accessory runs independently of app deployments. When changing its image,
environment, or mounted config, ensure credentials are available and run:

```sh
bundle exec kamal-backup validate
bin/kamal accessory reboot backup
```

## Recovery verification

Download a database snapshot into ignored local storage and verify SQLite can
read it. These commands do not replace the running production database:

```sh
mkdir -p tmp/backup-verification
bundle exec kamal-backup dump latest --database primary -o tmp/backup-verification/primary.sqlite3
sqlite3 tmp/backup-verification/primary.sqlite3 'PRAGMA integrity_check;'
bundle exec kamal-backup dump latest --database queue -o tmp/backup-verification/queue.sqlite3
sqlite3 tmp/backup-verification/queue.sqlite3 'PRAGMA integrity_check;'
```

Each integrity check should print `ok`. Dumps contain sensitive production data;
protect them and remove them after verification. Existing output files are not
silently overwritten.

This is a basic recovery check, not a full application restore drill. Periodically
restore into an isolated environment and verify application records and jobs.
Never test a production restore against the live database. Local restore/drill
commands require Restic installed locally; normal remote backup commands do not.

Repository checks do not alert anyone by themselves. Add external monitoring for
backup failures and stale snapshots before relying on unattended backups.

The off-server bucket protects against app server loss, but remains in the same
DigitalOcean account. A second copy in another account/provider is needed to
cover loss of that account.

# TODO

Move toward a shared activity model in small steps. Keep existing behavior working and do not add editing yet.

## 0. Remove the operational activity persistence experiment

- [x] Check for manual operation edits before removing the experimental table.
- [x] Remove operation persistence, import, and editing; return operations to YAML.
- [x] Leave existing act production details, questions, and documents untouched.

## 1. Introduce Activity for existing acts

- [x] Rename `ScheduleEntry` to `Activity`, still reading from YAML.
- [x] Expose `title` instead of `activity` and introduce `kind`, initially `act`.
- [x] Preserve act IDs, existing routes, and `schedule_entry_id` references.
- [x] Update consumers and verify the existing behavior with Rails and system tests.

## 2. Represent operations as activities

- [x] Use `Activity` for both acts and operations, still reading YAML.
- [x] Give operations explicit unique activity IDs while preserving act IDs and original operation URLs.
- [x] Remove the separate `OperationalActivity` model and select schedule rows by kind.
- [x] Keep act endpoints and existing database references isolated from operations.
- [x] Verify schedule filters, ordering, details, and ID isolation with Rails and system tests.

## 3. Introduce a common read interface for activity information

- [x] Expose execution, general notes, and pending confirmations through activity readers.
- [x] Expose technical information through a read-only `ProductionInformation` value object.
- [x] Read existing act production records and operation YAML without moving or overwriting data.
- [x] Use the readers on existing detail pages without changing their presentation or adding forms.
- [x] Verify missing data, current database edits, source isolation, and existing UI behavior with Rails and system tests.

## Later, one step at a time

- [ ] Persist activities without adding forms.
- [ ] Represent preparation actions as activities while retaining preparation groups and related acts.
- [ ] Introduce shared commissions and assignments, preserving unresolved source wording.
- [ ] Add editing only after the model is settled.

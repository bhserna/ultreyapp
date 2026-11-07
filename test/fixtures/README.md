# Test data

`activities.yml` is a static, test-owned dataset. It does not evaluate ERB or read files under `config/data`. Changes to source/reference snapshots must not silently change test records.

The 76 activity fixtures cover acts, operations, and ordered preparation actions, including shared preparation groups, multiple commissions, unknown and missing times, multiline instructions, and the existing route identities. Their explicit IDs are used by model, controller, and system tests. Edit the fixtures deliberately when a test scenario needs to change; do not regenerate them from production or source YAML as part of test setup.

Production details, questions, and documents are created explicitly by the tests that exercise them. Assertions should verify application behavior using those records, not compare spreadsheet snapshots with each other.

`preparations.yml` contains static preparation group fixtures with descriptive labels and explicit IDs matching their action fixtures. Headers and related-act lists are read from database records. No event YAML snapshot under `config/data` is required to run the suite.

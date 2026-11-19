# Integration Tests (AppSource end-user help)

This change adds integration tests to the Equipment Management project. The tests check that the steps of four business processes work together: equipment assignment, maintenance, equipment request approval and notifications. They run in the build pipeline and do not change how the app works for you.

TODO(verify): the tests have not been run yet. The pipeline result is pending.

## What you see
- Nothing changes in the app. No page, field, action or message is added or changed.
- No data is changed. The tests run in a transaction that is rolled back.

## Good to know
- The tests are for the project team. End users do not need to run them.
- To run them in a sandbox, use AL Test Runner in VS Code with the test app.

## Release notes
No change for users. Equipment Management gets integration tests for the assignment, maintenance, equipment request approval and notification processes.

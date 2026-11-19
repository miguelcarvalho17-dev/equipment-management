# Test coverage targets (contributor help)

This article is for people who change this repository. It is not an end-user article. The app does not change. The check reads the test code and the coverage register, and reports how many procedures the tests reach.

**The number is procedure reach, not line coverage.** A procedure counts as reached when a test calls it by name, or when the register has a trace to a test. The check does not measure lines or branches.

TODO(verify): the first Repo checks run on the pull request and the first manual Test Explorer coverage run are not done.

## What runs
| When | What happens |
|---|---|
| You open or update a pull request into `main` | "Repo checks" runs `repo_checks.py`, which calls the coverage check as check 5. Integrity errors fail the job. Below-target results are warnings. |
| You run the check locally | `python3 .github/scripts/coverage_check.py` prints the summary and the gaps. It works from any folder in the repository. |

The check is report-only in phase 1: `"enforce": false` in `.github/coverage/coverage-register.json`.

## Read the summary
The log shows three result lines, then the uncovered members and the Critical Process gaps:

```
Business Logic procedure reach: 44.0% (73/166, target 80)
API procedure reach: 0.0% (0/7, target 80)
Critical Process rule coverage: 77.8% (63/81, target 100)
```

- **Business Logic** and **API** count procedures. A member that no test calls is listed as uncovered.
- **Critical Process** counts rules. Each `Error(` or `TestField(` in a critical process object needs a positive test and a negative test. A gap is listed with its process, file, procedure and rule key.
- A `::warning::` line says the result is below target. In phase 1 this does not fail the job.
- A `::error::` line is an integrity error. It fails the job. Fix it before merge.
- Up to 20 uncovered members are listed per area. The step summary shows a table when the run is in GitHub Actions.

## When the check fails with an integrity error
| Message | What to do |
|---|---|
| `rule site ... has no entry in the coverage register` | You added an `Error(` or `TestField(` in a critical process object. Add a rule entry (see below). |
| `has no matching Error(/TestField( site any more` | You removed or renamed a message. Remove its rule entry. |
| `positiveNotApplicable needs a note` | Add a `note` that says why no success path exists. |
| `test ... does not exist as [Test]` | Check the codeunit ID and the procedure name. The procedure must have the `[Test]` attribute. |
| `does not exist` (object or member) | Check the ID or the procedure name in the register. |
| `does not run the page` | An API trace must call `TestPage "<page name>"` or `Page::"<page name>"` in the test. |

## Add a rule entry when you add an Error or TestField
1. Find the object and the procedure in the register (`criticalProcesses`, `rules`).
2. Add one rule with: `file`, `procedure` (the name of the member, for field triggers `<Field>.OnValidate`), and `key` (the first argument of `Error(`, or `TestField:<Field name>`).
3. If the same key appears twice in one procedure, the second one is `key#2`.
4. Add the positive test and the negative test as `{ "codeunit": <id>, "test": "<procedure name>" }`. The negative test checks the error text.
5. If no test exists yet, set `"gap": true` with empty lists, and add a `note`. Do not guess a test name.
6. If the rule has no success path (an unconditional error), set `"positiveNotApplicable": true` and a `note`.

Adding a message to a critical process object without a rule entry always fails Repo checks.

## Add a trace
Use a trace only when the check cannot see that a test reaches a member:
- an event subscriber (always needs a trace);
- a name that other code also declares (an ambiguous name);
- a procedure that runs only through a trigger or an event.

Add the trace to `traces` with `type`, `id`, `member`, the test (`codeunit`, `test`) and a `note`. Choose a test whose WHEN really raises the path. A test that only has a similar name does not count.

## Flip enforce (phase 2 only)
Set `"enforce": true` in `.github/coverage/coverage-register.json` only after the targets are met. Then a result below target fails the job. Do not change it in phase 1.

## Run the manual coverage check
Use this for a measured cross-check. It is not in CI.
1. Open the repository in VS Code with the AL Language extension, connected to a Business Central 28 or newer sandbox. Do not use production.
2. Open Test Explorer and choose the run profile **Coverage (Procedure)**. Run all tests in the test app.
3. Open an in-scope procedure in `app/src`. A CodeLens shows the tests that reached it.
4. Record the date and result in `docs/features/FR-047-test-coverage-targets.md`, table "Manual coverage runs".

Microsoft describes this profile in [Run AL tests from Visual Studio Code with Test Explorer](https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-test-explorer-vscode#view-code-coverage-information).

## Unit tests of the check
Run `python3 .github/scripts/test_coverage_check.py` from the repository. The tests cover the mapping rules, the procedure reach rules, the API page rule and the output.

## Release notes
None. This is build tooling. No change for end users.

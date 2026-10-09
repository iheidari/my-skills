---
name: create-pr
description: Review the branch, simplify it, run the repo's checks, then commit, push, open a pull request, and move the Linear ticket to In Review.
---

# Create PR

Run the five steps below in order. Invoking the skill is itself the approval for the whole
pipeline: run every step and open the PR without asking. Skip a step only when the invocation
names it (`/create-pr no review`, `no simplify`, `skip tests`) — skip exactly that step, silently, and run
the rest.

Requires the `gh` and `linearis` CLIs.

## 1. Review with thermos, then fix

Invoke the `thermos:thermos` skill via the Skill tool, scoped to this branch's diff against the
default branch (`main`/`master`) merge-base — pass the fixed point so the skill doesn't stop to
ask. If the branch *is* the default branch, use the fixed point that covers the uncommitted and
unpushed work (`@{upstream}`, else `HEAD~1`).

Work its synthesized findings:

- Fix **every P0 and P1**.
- Fix the **P2s that are easy**; record the rest with a one-line reason, and mention them in the
  PR body.
- Apply the **cleanups** the review suggests while you are in there.

Done when no P0/P1 remains. Re-run the review only if a fix was large enough to plausibly
introduce new findings.

## 2. Simplify

Invoke the `simplify` skill via the Skill tool and let it apply its changes to the working tree.

Done when simplify has finished and its edits are in the working tree.

## 3. Go green

Run the repo's checks in this order — the formatter rewrites files, so it goes first:

1. format
2. lint
3. typecheck
4. tests — every suite the repo defines: unit, integration, and E2E

Read the commands off the repo (`package.json` scripts, the framework's defaults; pnpm + Biome
in this monorepo). Run only the ones the repo actually defines: when a script is absent, report
it as missing and move on. Sweep the whole repo for test suites — workspace packages, separate
E2E runners (Playwright, Cypress) with their own scripts or configs — rather than stopping at
the root `test` script.

Then run the CI pipeline locally. Read every workflow that triggers on a pull request
(`.github/workflows/*.yml`, or the repo's CI config) and run each job's steps as CI runs
them. That includes steps that discover their own commands, like a loop over every `check:*`
script: run the whole set, not just the ones that match what you touched. Mirror CI's inputs,
such as its changed-files base. Where a step can't run locally (it needs secrets, or it deploys),
name it and why.

Done when every check that exists is green, every test suite you found has run, and every local
CI step passes. A failure is yours to fix: repair it and re-run from the formatter until the
run is green.

### Measure the change

Green says the tests ran; these numbers say whether they could have failed. Take them for the
files this branch changed, with the tools the repo already has:

- **Coverage** of the changed files, when the test runner has coverage configured.
- **Mutation score** of the changed files, when the repo configures a mutation tester (e.g. a
  Stryker config) — scope the run to those files, and list the surviving mutants by file and line.
- **Complexity**: the changed functions the repo's linter flags for complexity, when it has such
  a rule.

These are reported, not enforced: record each number for the PR body and move on, and write
"not configured" for a tool the repo lacks. Never install a tool or add a dependency to get a
number. Once a repo sets a threshold in its own config, that threshold is a check like any
other and belongs to the list above.

## 4. Open the PR

1. On the default branch (`main`/`master`), cut a feature branch first.
2. Stage the changes; write a commit message and a PR title + body from the diff. The body
   carries a **Shape** section, written for a reader who will judge the structure without
   reading the diff:
   - the data shape the change adds or alters (from the `/implement` report when there is one,
     else read off the diff);
   - the modules or packages touched, and every **new dependency between them** — an import
     that crosses a package or top-level directory boundary and did not exist on the base;
   - the tests added, each beside the behaviour or acceptance criterion it covers;
   - the Step 3 measurements, or "not configured";
   - the P2 findings left unfixed from Step 1, each with its reason.
3. Commit, push with `-u`, `gh pr create`.
4. Watch the PR's CI with `gh pr checks <n> --watch`. If a job fails, read its log
   (`gh run view <run-id> --log-failed`), fix it, re-run that step locally, then commit and push.

Done when `gh pr create` has returned a URL and every CI check on the PR passes. Report that URL.

## 5. Move the ticket to In Review

Find the Linear ticket the branch is for: the `0XC-NNN`-style identifier in the branch name, the
commit messages, or the PR title. If there is no identifier anywhere, skip this step and say so.

Move it with `linearis issues update <id> --status "In Review"`.

This step is not optional and has no "no ticket move" opt-out — without it the ticket sits in
In Progress forever, because merging the PR only moves it In Review → Done.

Done when the ticket reads In Review. Report the identifier alongside the PR URL.

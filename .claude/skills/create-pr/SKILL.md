---
name: create-pr
description: Simplify the branch, run the repo's checks, then commit, push, and open a pull request.
disable-model-invocation: true
---

# Create PR

Run the three steps below in order. Invoking the skill is itself the approval for the whole
pipeline: run every step and open the PR without asking. Skip a step only when the invocation
names it (`/create-pr no simplify`, `skip tests`) — skip exactly that step, silently, and run
the rest.

Requires the `gh` CLI.

## 1. Simplify

Invoke the `simplify` skill via the Skill tool and let it apply its changes to the working tree.

Done when simplify has finished and its edits are in the working tree.

## 2. Go green

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

Done when every check that exists is green and every test suite you found has run. A failure is yours to fix: repair it and re-run from
the formatter until the run is green.

## 3. Open the PR

1. On the default branch (`main`/`master`), cut a feature branch first.
2. Stage the changes; write a commit message and a PR title + body from the diff.
3. Commit, push with `-u`, `gh pr create`.

Done when `gh pr create` returns a URL. Report that URL.

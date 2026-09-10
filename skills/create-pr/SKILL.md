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

Done when every check that exists is green and every test suite you found has run. A failure is yours to fix: repair it and re-run from
the formatter until the run is green.

## 4. Open the PR

1. On the default branch (`main`/`master`), cut a feature branch first.
2. Stage the changes; write a commit message and a PR title + body from the diff.
3. Commit, push with `-u`, `gh pr create`.

Done when `gh pr create` returns a URL. Report that URL.

## 5. Move the ticket to In Review

Find the Linear ticket the branch is for: the `0XC-NNN`-style identifier in the branch name, the
commit messages, or the PR title. If there is no identifier anywhere, skip this step and say so.

Move it with `linearis issues update <id> --status "In Review"`.

This step is not optional and has no "no ticket move" opt-out — without it the ticket sits in
In Progress forever, because merging the PR only moves it In Review → Done.

Done when the ticket reads In Review. Report the identifier alongside the PR URL.

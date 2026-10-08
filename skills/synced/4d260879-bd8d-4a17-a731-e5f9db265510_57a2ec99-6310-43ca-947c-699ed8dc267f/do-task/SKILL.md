---
name: do-task
description: Pick up a task from tasks/, mark it in-progress, implement it (in an isolated git worktree only when another task is already in flight — otherwise a local branch), commit, then run focused passes (docs, test coverage, a11y, SEO/GEO/AEO, simplify, thermos review) committing after each, open a PR, watch its CI to green, then mark the task done only after you confirm the PR is merged. Use when the user runs /do-task [NNN] or says "do task NNN".
disable-model-invocation: true
---

Execute a task from the `tasks/` backlog end-to-end: pick → plan → mark **in-progress** →
implement on a branch (or worktree) → commit → **docs** → **test coverage** → **a11y** →
**SEO/GEO/AEO** → **simplify** → **thermos** review + fix → **full test gate** (unit + e2e
integration) → PR (committing after each pass) → **watch CI to green**.
The task is **not** marked `done` until the user confirms the PR merged — at which point you
finalize and clean up. The skill argument is an optional task number (`/do-task 3`,
`/do-task 003`, or just `/do-task`).

Read `tasks/README.md` first so you follow the backlog conventions.

## Step 1 — Resolve which task
- **Number given** (e.g. `3`): normalize to zero-padded `NNN` and open the matching
  `tasks/NNN-*.md`. If none matches, list the available `todo` tasks and stop.
- **No number**: scan `tasks/*.md` (not `tasks/_done/`) for `status: todo`. Pick the
  **highest `priority`** (`high` > `medium` > `low`); break ties by **lowest `NNN`**
  (oldest first). If nothing is `todo`, say so and stop.

Read the whole task file. If `status` is already `in-progress` or `done`, surface that and
confirm before proceeding (it may already be underway in another worktree).

## Step 2 — Plan & confirm
Restate your understanding in 2–4 sentences and lay out a short implementation plan keyed to
the task's **Acceptance criteria**. This is the one interactive gate — **confirm with the
user before creating the workspace and writing code.** (Matches the backlog's "plan first,
confirm, then execute" rule.)

## Step 3 — Choose the workspace, then mark the task in-progress
Decide **worktree vs. local branch** based on whether another task is already in flight, then
create the workspace and set the task `status: in-progress`.

### 3a — Is another task already in flight?
Check this **before** you mark the current task in-progress. Another task is in flight if **any**
of these is true (`git worktree list` is the most reliable signal — a worktree task's
`in-progress` status lives on its own branch, so scanning the main checkout's task files alone
can miss it):
- `git worktree list` shows a worktree **other than** the main repo, **or**
- the main checkout is on a **non-default branch** or has uncommitted changes (already busy), **or**
- any *other* task file is marked `status: in-progress`.

### 3b — No other task in flight → **local branch** (no worktree)
Work directly in the main checkout — its deps and gitignored env files are already in place, so
the user can run/test the app immediately.
1. Derive the **branch** name: `<prefix>/NNN-slug`, where `prefix` maps from the task's `type:` —
   `feature→feat`, `bug→fix`, `chore→chore`, `refactor→refactor`, `docs→docs` (default `feat`).
2. `git fetch origin && git switch -c <branch> origin/main` (branch off up-to-date `main`).

### 3c — Another task is in flight → **isolated worktree**
Isolate this task so the parallel work doesn't collide.
1. Derive names from the task file:
   - **Worktree dir**: `../<repo>-worktrees/NNN-slug` (sibling of the repo, e.g.
     `../milemark-worktrees/001-server-synced-saved-campgrounds`).
   - **Branch**: `<prefix>/NNN-slug` (same prefix mapping as 3b).
2. Create it off the up-to-date default branch:
   `git fetch origin && git worktree add ../<repo>-worktrees/NNN-slug -b <branch> origin/main`
3. From here on, **run every command inside the worktree dir** (use absolute paths / `git -C`;
   avoid `cd` where the harness would prompt).
4. Install deps in the worktree — this is a **hoisted pnpm monorepo**, so the worktree has no
   `node_modules` until you install: run `pnpm install` at the worktree root.
5. **Copy gitignored env files so the app runs locally.** A fresh worktree is a clean checkout
   and has none of the gitignored `.env*` files the app needs. Copy each gitignored env file
   from the main repo into the same relative path in the worktree:
   ```
   git -C <main-repo> ls-files --others --ignored --exclude-standard \
     | grep -E '(^|/)\.env' \
     | while read -r f; do
         mkdir -p "<worktree>/$(dirname "$f")"
         cp "<main-repo>/$f" "<worktree>/$f"
       done
   ```
   Today that is `apps/web/.env.local` and `apps/mobile/.env`. Confirm afterward that each
   expected env file landed in the worktree.

### 3d — Mark in-progress (both paths)
In the chosen workspace, set the task file's `status: in-progress` and fill `branch:` with the
branch name. (Do **not** move it to `_done/` yet — that happens only after the PR merges, Step 16.)

## Step 4 — Implement (TDD)
Work **test-first**: for each testable acceptance criterion, write a failing test, make it
pass, then refactor. Cover the new behavior with tests before moving on.

Build the task to satisfy **every** acceptance criterion. Follow the codebase conventions in
`CLAUDE.md` (Pages router, `@/*` alias, keep `packages/shared` framework-free, mirror bbox
snapping, don't expose admin fields, etc.). When a criterion is genuinely infeasible or wrong,
stop and flag it rather than silently skipping.

## Step 5 — Update docs & verify (before committing)
Two gates must both pass **before** you commit (and well before the PR):

1. **Docs** — create or update any documentation the change makes necessary: `CLAUDE.md`
   (architecture/conventions), the relevant `README.md`(s), `apps/*/.env.example` for new env
   vars, and inline doc comments. Don't leave docs describing the old behavior.
2. **Build, lint, and tests all green** — run and confirm, fixing every failure before
   proceeding:
   - **Build**: `pnpm build` (web) — this also type-checks `apps/web` and generates
     the gitignored `next-env.d.ts`, so don't run a standalone `tsc` for web in a clean
     worktree (it fails on `*.png` and other static-asset imports without it).
   - **Typecheck**: `pnpm --filter mobile exec tsc --noEmit` and the shared package
     typecheck (web is covered by the build above).
   - **Lint**: `pnpm lint`.
   - **Tests**: the project's test command, including the tests you added for this task.

   **Never open the PR with a red build, failing lint, or failing tests.**

## Step 6 — Commit the implementation
Once docs and the build/lint/test gates from Step 5 are green, stage and commit the work with a
conventional message (`<prefix>: <title> (task NNN)`). The task file is included in this commit
at `status: in-progress` (it stays there — do **not** mark it `done` or move it to `_done/`
now). End the commit message with:
`Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

**Do not open the PR yet** — the review-and-cleanup passes (Steps 7–12) plus the full test gate
(Step 13) run first, on the
committed branch, so the PR opens already-reviewed. **After each of Steps 7–10, if any files
changed, commit them** (conventional message + the same `Co-Authored-By:` footer) before moving
to the next step; if a step changed nothing, say so and skip its commit.

## Step 7 — Documentation pass
Re-check the project docs now that the implementation is final — this catches anything the
Step 5 docs gate missed. Update whatever the change makes necessary: `CLAUDE.md`
(architecture/conventions), the relevant `README.md`(s), `apps/*/.env.example` for new env vars,
task-backlog notes, and inline doc comments. Don't leave any doc describing the old behavior.
Commit any doc changes (`docs: update docs for task NNN`).

## Step 8 — Test-coverage pass
Confirm the change is well covered by **unit** *and* **integration** tests, and add what's
missing. Pick the integration layer from the **type of change** and follow that skill's rules:
- **`apps/web` API / route handlers / `lib/*` server logic** → the `api-integration-testing`
  skill (drive the real `/api/v1/*` path; see `apps/web/test/`).
- **`apps/web` UI / pages / components** → the `webapp-integration-testing` skill.
- **`apps/mobile` screens / navigation / stores** → the `react-native-integration-testing`
  skill.

(All three build on the shared `base-integration-testing` skill — apply it too.) Write new tests
test-first where practical, run the full **build / lint / test** gates from Step 5, and commit
any new tests (`test: cover task NNN`).

## Step 9 — Accessibility pass (web/mobile only)
**Skip entirely if the change touches neither `apps/web` nor `apps/mobile` UI** — say so and
move on. Otherwise run the **reviewing-a11y** skill against the changed pages/components to check
WCAG 2.2 / WAI-ARIA roles and ADA concerns, and fix what it surfaces (labels, roles, contrast,
focus order, etc.). Re-run the Step 5 gates and commit any fixes (`fix: a11y for task NNN`).

## Step 10 — SEO / GEO / AEO pass (web/mobile only)
**Skip entirely if the change touches neither `apps/web` nor `apps/mobile` user-facing content**
— say so and move on. Otherwise run the **seo-geo-aeo** skill against the affected pages/screens
(meta tags, structured data / JSON-LD, headings, answer-engine readiness, etc.) and apply the
fixes that fit the change. Re-run the Step 5 gates and commit any fixes
(`fix: seo/geo/aeo for task NNN`).

## Step 11 — Simplify
Run the **simplify** skill (`/simplify`) to review the changed code for reuse, simplification,
efficiency, and altitude cleanups, and apply its fixes. (Simplify is quality-only — it does not
hunt for bugs; the thermos pass in Step 12 does that.)
- Re-run the **build / lint / test** gates from Step 5 and fix any failure simplify introduced.
- Commit the result (`refactor: simplify task NNN`, same Co-Authored-By footer). If simplify
  changed nothing, say so and skip the commit.

## Step 12 — Thermos review & fix findings
Run the **thermos** skill (`/thermos`) on the branch diff (vs `origin/main`) — it launches the
two thermo-nuclear reviewers (bug/security/breakage + code-quality) in parallel and synthesizes
prioritized findings (P0 blocking → P3 nit). Then act on them:

- Fix **all P0 and P1** findings.
- Fix **P2** findings that are easy; leave the rest noted.
- Do any **easy cleanups** the review surfaces while you're in there.
- Whatever is **left** (deferred P2s, P3s, anything not worth doing now) is recorded and posted
  as a PR comment when the PR is opened (Step 14) — nothing is dropped silently.
- Re-run the **build / lint / test** gates from Step 5 after fixing, then commit
  (`fix: address thermos findings (task NNN)`, same footer). If there was nothing to fix, skip
  the commit.

Keep a short written list of the thermos findings (severity, file:line, **fixed** vs.
**deferred** with a one-line reason) to paste into the PR comment in the next step.

## Step 13 — Full test gate (unit + e2e integration)
Before opening the PR, run the **complete** test suite — unit **and** end-to-end integration —
for **every** app the change touched, and confirm all pass. The default `pnpm test` **excludes**
the integration suites, so they must be run explicitly:
- **`apps/web` touched** → `pnpm --filter web test` (unit) **and** `pnpm --filter web
  test:integration` (the Docker-backed `/api/v1/*` e2e API suite — its `globalSetup` brings up
  the PostGIS test DB on `:5433` and a `next dev` server on `:3100` itself).
- **`apps/mobile` touched** → `pnpm --filter mobile test` (the `jest-expo` suite, which includes
  the React Native e2e integration tests — screens + navigation, iOS & Android).
- **`packages/shared` touched** → `pnpm --filter shared test`.

If anything is red, **fix it** (the test or the code, whichever is wrong), re-run until
**everything passes**, and **commit the fixes** (`test: fix tests for task NNN` or
`fix: … (task NNN)`, same Co-Authored-By footer) before continuing. **Never open the PR with any
unit or integration test failing.** If nothing needed fixing, say so and skip the commit.

## Step 14 — Open the PR, post the review, and watch CI to green
1. Push the branch and open the PR with `gh pr create`. The PR body should summarize the change,
   restate the acceptance criteria as a checklist, and link the task. End the PR body with:
   `🤖 Generated with [Claude Code](https://claude.com/claude-code)`
2. Capture the PR URL/number from `gh`.
3. **Post the thermos review as a single PR comment for the record** (`gh pr comment <url>
   --body …`): list the findings by severity with file:line, marking each **fixed** or
   **deferred** (one-line reason for anything left). If the review came back clean / fully
   addressed, say so.
4. **Watch the CI build until it finishes successfully — do not hand off on a red or pending
   build.** Poll the PR's checks (`gh pr checks <url> --watch`, or repeated `gh pr checks <url>`
   / `gh run list`/`gh run watch` against `.github/workflows/ci.yml`) until every required check
   has completed.
   - **All checks pass** → continue to Step 15.
   - **A check fails** → inspect the failing run (`gh run view <run-id> --log-failed`), diagnose
     the cause, **fix it on the branch** (the code or the test, whichever is wrong — never just
     re-run a genuinely red build hoping it goes green), re-run the relevant local gate from
     Step 5/Step 13 to confirm, then commit (`fix: … (task NNN)`, same `Co-Authored-By:` footer)
     and push. Watch the new CI run and repeat until CI is fully green.
   - If CI stays red after a reasonable effort, or fails for an infra/flake reason outside the
     change, **stop and tell the user** with the failing run link and what you found rather than
     handing off as if it passed.

## Step 15 — Report & hand off (await merge)
Give the user: the PR link, a one-line summary of what was built, **confirmation that CI is
green** (from Step 14.4), the review findings by severity, what you fixed vs. deferred (with
reasons), and the workspace (branch, plus worktree path if one was created). The task is
**in-progress, not done**.

**Do not merge the PR, and do not mark the task done.** Tell the user explicitly: *"Tell me
once the PR is merged and I'll finalize the task (mark it done, open the finalize PR, and clean
up the worktree)."* Then stop and wait for that confirmation.

## Step 16 — (When the user says the PR merged) Finalize the task
Only run this once the user confirms the **feature PR is merged**. Direct pushes to `main` are
blocked by the `.githooks/pre-push` hook, so the done-flip lands via its own small PR.

1. **Sync the main checkout** to the merged state:
   ```
   git -C <main-repo> fetch origin
   git -C <main-repo> checkout main        # if it was left on the feature branch (local-branch case)
   git -C <main-repo> pull --ff-only origin main
   ```
2. **Open the finalize PR** (status flip + move to `_done/`). After the sync, `tasks/NNN-slug.md`
   exists on `main` at `status: in-progress`:
   ```
   git -C <main-repo> switch -c chore/NNN-done origin/main
   ```
   - Set the task file's `status: done`.
   - Move it: `git -C <main-repo> mv tasks/NNN-slug.md tasks/_done/NNN-slug.md`.
   - Commit `chore: mark task NNN done` (same `Co-Authored-By:` footer), push, and
     `gh pr create` with the generated footer. This finalize PR is tiny; you don't need to wait
     for it to merge before cleaning up.

## Step 17 — (When the user says the PR merged) Clean up the workspace
Done alongside Step 16, after the feature PR merged.

- **Worktree case**: remove the worktree and delete its folder, then delete the now-merged
  local feature branch (it's free once the worktree is gone):
  ```
  git -C <main-repo> worktree remove ../<repo>-worktrees/NNN-slug
  git -C <main-repo> branch -d <feature-branch>
  ```
  (Use `git worktree remove --force` only if it refuses due to leftover untracked files — e.g.
  the copied env files — and call that out.) GitHub usually deletes the remote branch on merge;
  if it didn't, `git -C <main-repo> push origin --delete <feature-branch>`.
- **Local-branch case**: you're already back on `main` from Step 16; just delete the merged
  feature branch: `git -C <main-repo> branch -d <feature-branch>`.

Finally, report to the user: the task is `done` and moved to `tasks/_done/`, the finalize PR
link, and that the workspace was cleaned up.

---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
---

Implement the work described by the user in the spec or tickets. Run every step below in order.

## 1. Workspace

Branch name: `<feat|fix|refactor>/<ticket-id>-<short-kebab-slug>` — the slug starts with the Linear ticket identifier (e.g. `feat/0XC-123-add-oauth-login`). Drop the `<ticket-id>-` prefix only when there is no ticket.

Decide where to build by looking at the checkout you are in:

- **On the default branch** (`main`/`master`) with a clean tree: `git fetch origin && git pull --ff-only`, create the branch, switch to it, and build here.
- **Anything else** — on a feature branch, or a dirty tree — that work is in progress. Do not disturb it: build the new ticket in a worktree (below). Ask first only if the current branch is for the *same* ticket you were just asked to implement; then continue on it.

### Creating the worktree

Worktrees live in a sibling directory of the **main** checkout: `<main>/../<repo>-worktrees/<branch-slug>`, where `<branch-slug>` is the branch name with `/` replaced by `-` (`feat/0XC-123-add-oauth-login` → `feat-0XC-123-add-oauth-login`). Get `<main>` from the first line of `git worktree list` — `..` relative to the current directory is wrong when you are already inside a worktree.

```
git fetch origin
git worktree add -b <branch> <main>/../<repo>-worktrees/<branch-slug> origin/<default-branch>
```

Then `cd` into the worktree and do the rest of the work there — every command in the steps below runs from the worktree, not the original checkout. Never `git switch` in the original checkout; its in-progress work stays untouched.

Before creating, run `git worktree list`. If a worktree for this branch already exists, `cd` into it instead of creating a second one.

After `cd`, bootstrap the worktree so builds and tests work: install dependencies (`pnpm install`), and copy over the untracked local files the repo needs — `.env*`, and anything the README or `.gitignore` marks as required local config. Report what you copied.

Leave the worktree in place when you finish; it is removed after the PR merges with `git worktree remove <path>`.

## 2. Ticket status

If the work has a Linear ticket, use `linearis` (fall back to the Linear MCP):

- Move it to **In Progress**.
- Remove the **Ready to play** label if present.

Skip this step when there is no ticket; report but don't block if either update fails.

Skills named in the steps below (`how`, `tdd`, `principle-*`) are marked user-invoked only, so
**read** them rather than invoking them: open `<name>/SKILL.md` from `.claude/skills/` in the
project, else `~/.claude/skills/`, and follow it.

## 3. Understand and design

Size the work first. A change confined to one or two files whose shape is obvious from the
ticket (copy, config, a small isolated fix) skips this step — say so in the report with a
one-line reason. Everything else runs it before any test or code is written.

- **Understand.** Follow the `how` skill over the code the ticket touches, at its simple path
  unless the change spans several modules or services.
- **Name the data shape.** Write down the types or records the change adds or alters, and the
  structure that organizes them, per `principle-model-the-domain`: a state machine over
  scattered booleans, a table or registry over branching, a typed model over repeated shape
  assumptions. The tests in Step 4 are written against this shape.
- **Bug tickets: reproduce, then find the root cause**, per `principle-fix-root-causes`.
  Reproduce the defect on the surface the ticket describes (the running app, the endpoint, the
  CLI) before touching code; when it won't reproduce directly, instrument until it does. Trace
  the symptom to its cause with runtime evidence, not a guess. If the bug cannot be reproduced,
  stop and report what you tried — a fix for an unreproduced bug is a guess.

**Done when** the report can state the data shape (or the skip reason) and, for a bug, the
repro and its root cause.

## 4. Build

Follow the `tdd` skill where possible, at the seams Step 3 named.

For a bug, the first test reproduces it and fails for the root cause from Step 3. Commit that
failing test on its own before the fix, so the history shows red, then green. If a pre-commit
hook rejects a failing test, fold it into the fix commit instead and note that in the report —
never bypass the hook.

Run typechecking regularly, single test files regularly, and the full test suite once at the
end — all green before the Step 6 commit. The bug's failing-test commit is the one deliberate
exception.

## 5. Prove it works

Green tests are not proof. Per `principle-prove-it-works`, exercise the change on the real
surface and read the actual result: start the app and drive the changed UI (Playwright or
Chrome automation when the repo has it — screenshot it), call the changed endpoint, run the
changed command. For a bug, re-run the Step 3 repro and confirm it no longer fires.

When the surface needs something you don't have (a physical device, a real purchase,
production data, a secret), name exactly what was missing in the report instead of claiming a
pass. A failure here goes back to Step 4.

**Done when** the report holds the evidence — the command and its output, or the screenshot —
or names what blocked it.

## 6. Commit

Commit to the current branch, and report what you built — the data shape, the root cause for a
bug, the Step 5 evidence, plus the worktree path, if you built in one. Review happens in
`/create-pr`, not here.

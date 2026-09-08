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

## 3. Build

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end — all green before you commit.

## 4. Commit

Commit to the current branch, and report what you built — plus the worktree path, if you built in one. Review happens in `/create-pr`, not here.

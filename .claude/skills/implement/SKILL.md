---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
---

Implement the work described by the user in the spec or tickets. Run every step below in order.

## 1. Branch

Branch name: `<feat|fix|refactor>/<ticket-id>-<short-kebab-slug>` — the slug starts with the Linear ticket identifier (e.g. `feat/0XC-123-add-oauth-login`). Drop the `<ticket-id>-` prefix only when there is no ticket.

- **On the default branch** (`main`/`master`): `git fetch origin && git pull --ff-only`, then create the branch and switch to it.
- **Already on a branch**: ask the user whether to continue on it or cut a new branch off an updated default, and do what they say.

## 2. Ticket status

If the work has a Linear ticket, use `linearis` (fall back to the Linear MCP):

- Move it to **In Progress**.
- Remove the **Ready to play** label if present.

Skip this step when there is no ticket; report but don't block if either update fails.

## 3. Build

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end — all green before you commit.

## 4. Commit

Commit to the current branch, and report what you built. Review happens in `/create-pr`, not here.

---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets. Run every step below in order.

## 1. Branch

- **On the default branch** (`main`/`master`): `git fetch origin && git pull --ff-only`, then create a branch for this work (`<feat|fix|refactor>/<short-kebab-slug>`) and switch to it.
- **Already on a branch**: ask the user whether to continue on it or cut a new branch off an updated default, and do what they say.

## 2. Build

Use /tdd where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end — all green before step 3.

## 3. Review with thermos, then fix

Invoke the `thermos` skill, scoped to this branch's diff, and work its synthesized findings:

- Fix **every P0 and P1**.
- Fix the **P2s that are easy**; record the rest with a one-line reason.
- Apply the **cleanups** the review suggests while you are in there.

Re-run typecheck, lint, and the full test suite after fixing. Done when no P0/P1 remains and the suite is green.

## 4. Commit

Commit to the current branch, and report what you fixed versus deferred.

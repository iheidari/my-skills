---
name: autopilot
description: Unattended end-to-end run on a Linear ticket — implement it, open a PR, review the PR, and post the review as a PR comment.
disable-model-invocation: true
---

# Autopilot

The run is **unattended**: no user is available from start to finish. Wherever a step below — or
a skill it invokes — says to ask the user, take the safest option, note it in the final summary,
and continue; stop cleanly only when no safe option exists. A step that can't reach its
**done when** stops the run with a report.

Three guardrails, each stated as the behaviour that satisfies it:

- Every commit lands on the feature branch, leaving `main`/`master` untouched.
- The PR is handed over open — a human merges, approves, or closes it.
- The ticket ends **In Review** at most; a human marks it done.

## 0. Clean start and borrowed skills

Check out the default branch (`main`/`master`), `git fetch && git pull --ff-only`, and confirm
the working tree is clean. A dirty tree stops the run.

## 1. Implement

**Ticket argument** (`/autopilot 0XC-123`): that ticket is the target — skip the Linear query
and go straight to marking it in-progress. If it already carries an open PR or an in-progress
state, report that and stop: a human moved it for a reason worth knowing first.

**No argument**: query Linear (`linearis`, falling back to the Linear MCP) for **unstarted**
tickets labelled **Ready to play**. Take the highest priority (Urgent > High > Medium > Low > No
priority; ties broken by oldest created), passing over any ticket with an open PR or an
in-progress state. Nothing qualifies → end the run reporting **"no work available."**

Mark the ticket in-progress. Then launch a **subagent** to run `/implement` against it, starting
from the default branch so `/implement` cuts its own branch and never reaches its "ask the user"
path.

Record the branch it created and confirm the branch has commits. If `/implement` fails or the
branch has no commits, restore the ticket's previous state while holding the **Ready to play**
label back — a failed ticket waits for a human before it re-enters the queue — then report and
stop.

**Done when** you hold a branch name with commits on it.

## 2. Create PR

Confirm the checkout is on Step 1's branch, then run `/create-pr`. It runs its own review,
simplify, and checks, and opens the PR without asking.

Before it opens the PR, confirm the branch is free of borrowed skills — staged or committed —
and unstage or remove any that got through.

Capture the PR URL and number. On failure, retry once, then stop and report.

**Done when** `gh` has returned a PR URL and number.

## 3. Review and comment

Run `/pr-review <PR number>`. Unattended overrides for its two pause points:

- **Uncommitted changes**: everything in the tree belongs to this session, so proceed.
- **Ask first items**: continue without an answer — leave the item unfixed and keep it in the
  **Needs your decision** section of the report.

When `/pr-review` produces its final report, write the complete report to a temp file with
Write, then post it: `gh pr comment <number> --body-file <file>`. Link the PR on the Linear
ticket if it isn't already linked.

**Done when** the PR carries one comment holding the full report.

## Final summary

Ticket ID, branch, PR URL, the verdict line from the report, and every decision you made in
place of asking.

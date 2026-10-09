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

The run needs `implement`, `create-pr`, `pr-review`, and the skills they read or invoke: `how`,
`tdd`, `principle-model-the-domain`, `principle-fix-root-causes`, `principle-prove-it-works`,
`principle-test-behavior-not-implementation`, `thermos`, `thermo-nuclear-review`,
`thermo-nuclear-code-quality-review`, `simplify`, and `resolving-merge-conflicts`. A skill
already available — in this repo's `.claude/skills/` or `~/.claude/skills/` — needs nothing. For
the rest, clone https://github.com/iheidari/my-skills to a temp directory and copy each missing
skill folder into this repo's `.claude/skills/`: most live at `skills/<name>/`, the three thermos
skills at `skills/thermos/skills/<name>/`. A skill that is neither available nor in the clone is
noted in the final summary, not copied.

Two of those need more than a folder copy:

- **`thermos`** launches two subagent types whose definitions live outside the skill folders, at
  `skills/thermos/agents/<name>.md` in the clone. When you borrow thermos, copy both files into
  this repo's `.claude/agents/` and treat them as borrowed too. A borrowed copy answers to
  `thermos`, not `thermos:thermos` — invoke whichever name resolves. If the two subagent types
  still don't resolve when thermos runs, launch two general-purpose subagents instead, each told
  to read its agent file and the matching `thermo-nuclear-*` skill as its rubric, and say so in
  the final summary: a review that silently ran without its rubric is worse than none.
- **`simplify`** is not in the clone; it comes from the harness. When it doesn't resolve, Step 2
  runs `/create-pr no simplify` and the final summary says the simplify pass was skipped.

Those copies are **borrowed**: they serve this session only, and every commit the run makes
stays free of them. Keep the list of what you borrowed, and exclude the folders with the file
tools rather than shell redirection:

- Read `.git/info/exclude` (create it with Write if absent).
- Append a `.claude/skills/<name>/` line per borrowed folder, and a `.claude/agents/<name>.md`
  line per borrowed agent file, with Edit, preserving every line already in the file.
- Run `git status --short` on its own. Borrowed paths absent means the exclusion took; still
  listed means stop and report, before anything borrowed reaches a commit.

**Done when** the tree is clean, every skill above resolves or is noted, and `git status --short`
lists no borrowed path.

## 1. Implement

**Ticket argument** (`/autopilot 0XC-123`): that ticket is the target — skip the Linear query
and go straight to marking it in-progress. If it already carries an open PR or an in-progress
state, report that and stop: a human moved it for a reason worth knowing first.

**No argument**: query Linear (`linearis`, falling back to the Linear MCP) for **unstarted**
tickets labelled **Ready to play**. Take the highest priority (Urgent > High > Medium > Low > No
priority; ties broken by oldest created), passing over any ticket with an open PR or an
in-progress state. Nothing qualifies → end the run reporting **"no work available."**

**Acceptance criteria are the entry ticket.** Read the candidate before marking it in-progress.
It qualifies only when its description carries acceptance criteria a human wrote: statements you
could each turn into a check, under an "Acceptance criteria" heading or its plain equivalent.
Step 3 measures the PR against them, and without them it falls back to the PR's own "How to
test" notes — which this run wrote, so the run would be grading itself. A ticket without
criteria is passed over (no argument) or stops the run (ticket argument), untouched in Linear
and named in the final summary so a human can add them. Never write the criteria yourself.

Mark the ticket in-progress. Then launch a **subagent** to run `/implement` against it, starting
from the default branch so `/implement` cuts its own branch and never reaches its "ask the user"
path. Give the subagent this unattended override for `/implement` Step 4:

- **Behaviour ships with a test.** Every acceptance criterion that describes behaviour gets a
  test written per `principle-test-behavior-not-implementation`, failing before the code that
  satisfies it and passing after — features included, not only bugs. The `tdd` skill's "prefer no
  new test over a bad test" still holds where no cheap executable path exists (a physical device,
  a real purchase, a visual judgment): there, skip the test and have the report name the
  criterion and what was missing. With nobody watching, the tests are what keeps the work on
  the ticket.
- The report lists each criterion beside the test that covers it, or the reason none does.

Record the branch it created and confirm the branch has commits. If `/implement` fails or the
branch has no commits, restore the ticket's previous state while holding the **Ready to play**
label back — a failed ticket waits for a human before it re-enters the queue — then report and
stop.

**Done when** you hold a branch name with commits on it.

## 2. Create PR

Confirm the checkout is on Step 1's branch, then run `/create-pr`. It runs its own review,
simplify, and checks, and opens the PR without asking. Hand it Step 1's report — the data shape
and the criterion-to-test list — for the PR body's **Shape** section.

Keep a tally as it runs, for the final summary: thermos findings by priority and how many were
fixed, whether simplify changed any file, and the measurements it reported.

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
place of asking. Then:

- **Passed over**: each ticket skipped for missing acceptance criteria, by ID.
- **Tests**: criteria covered by a new test, and each one that isn't with its reason.
- **What each stage changed**: thermos findings by priority and how many were fixed; whether
  simplify changed anything; what `/pr-review` fixed and pushed. A stage that keeps reporting
  nothing across runs is a stage to cut.
- **Measurements**: the numbers `/create-pr` reported, or "not configured".

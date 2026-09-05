---
name: review-pr
description: Test a PR against its ticket's acceptance criteria, fix what fails, push, and report what's left.
disable-model-invocation: true
model: opus
effort: medium
---

# Review PR

Take a pull request from wherever it is to **green**: test it against its ticket's
**acceptance criteria**, fix every automated failure, push the fixes, and hand the user a
checklist of what's confirmed, what you fixed, what needs their call, and what still needs a
human.

The run is autonomous. It pauses for exactly two things: **uncommitted changes** in the
current tree (Step 2), and an **Ask first** item — a fix that would change what the product
does (Step 5). Everything else proceeds without confirmation.

Argument: a PR number (`/review-pr 46`), a PR URL, or empty. Requires `gh`.

## 1. Resolve the PR

`gh pr view <target> --json number,title,body,headRefName,baseRefName,url,state,mergeable,mergeStateStatus`

- **Argument given**: that's the target, whatever its state — retesting a merged PR on
  request is valid.
- **On the default branch**: take **the next open PR** — `gh pr list --state open --json
  number,createdAt`, oldest `createdAt`. No open PRs: say so and stop.
- **On a feature branch with an open PR**: that branch's PR.
- **On a feature branch whose PR is merged/closed**: say so, then fall through to the next
  open PR.
- **On a feature branch that never had a PR**: **stop** and ask what to do — test a specific
  PR, or switch to the default branch and take the next one?

## 2. Check out and merge clean

- Already on `headRefName`: skip ahead.
- Uncommitted changes (`git status --porcelain` non-empty): **stop**, tell the user to commit
  or stash. Clean tree: `gh pr checkout <number>` (fall back to fetching `headRefName`).
- `mergeable: CONFLICTING`, or a local merge of `baseRefName` conflicts: merge the base in
  and resolve, via the `resolving-merge-conflicts` skill when available. Tell the user you're
  resolving and keep going.

## 3. Read the ticket

Find the ticket id (e.g. `0XC-173`) in the PR title, body, then `headRefName`. Read it with
`linearis issues read <id>`, falling back to the Linear MCP `get_issue`. Keep three things:

- **Acceptance criteria** — the bar the PR is measured against, and the source of the
  checklist in Step 4.
- **Intent** — what the change was meant to do, in the ticket author's own words.
- The ticket **`url`**, for the links block in Step 8. Resolved once, here.

Intent is the run's yardstick, so read it before running anything. It's what separates "this
check failed because the code is wrong" from "this check failed because the author changed
the behavior on purpose" — and a fix built on that backwards reverts someone's decision and
pushes it.

No id anywhere, or Linear unreachable: say so and fall back to the PR body in Step 4. Report
only the ticket and URL you actually read.

## 4. Build the checklist from the acceptance criteria

The **acceptance criteria** from Step 3 are the checklist. Take each criterion as a testable
item, including the ones the PR author's own notes never mention — the criteria are the bar,
and a PR that passes its author's steps while missing a criterion has not met it.

- Read the PR `body` too, for the section headed **how to test** (case-insensitive; also
  "Testing", "Test plan", "QA", "How to verify"). Its steps are the author's how — concrete
  commands, URLs, fixtures, seeds — so fold them into the criteria they serve rather than
  listing them separately.
- **No reachable ticket or no criteria on it**: build the checklist from that "How to test"
  section instead, and say that's what you're doing.
- **Neither**: **stop**, report there's nothing to build a checklist from, and list the
  ticket's and body's headings so the user can point you at one.

## 5. Classify every item

Each checklist item lands in exactly one bucket:

- **Automatable** — runs in the shell with no human eye, and any fix it needs is mechanical:
  install a dependency, `typecheck`, `lint`, `format:check`, tests, a build smoke check, a
  script, a `curl`.
- **Ask first** — you *could* run and fix it, but the fix is a judgment call: it changes what
  the product does, undoes something the ticket calls deliberate, reaches green by weakening
  a check, or edits code outside this PR's scope. Run the check to see the failure; surface
  the failure verbatim as a question.
- **Manual** — needs a human, a device, or an aesthetic call. Read the evidence rule in
  Step 6 first: several items that look manual are ones you can verify yourself.

**An item you can't confidently place is an Ask first item.** Only a confidently-Automatable
item is eligible for an automatic fix, because guessing Automatable means pushing a change
nobody approved.

Show the classified checklist **before** running anything.

## 6. Run the automatable items

- **Detect the package manager** from lockfiles (`pnpm-lock.yaml`, `package-lock.json`,
  `yarn.lock`) or the repo's `CLAUDE.md`, and honor whichever it names.
- **Install deps** when an item asks, or when `package.json`/the lockfile is in
  `gh pr diff <number> --name-only`.
- Run each item and **capture pass/fail plus the key output lines**. Run the read-only checks
  (typecheck, lint, tests) even for a vaguely worded item — cheap signal. Run formatters and
  other writes only when an item asks.
- An item that deploys, publishes, deletes, or hits production is **Manual** — mark it and
  say why.

**Fix what fails, three attempts, then stop.** Diagnose, fix, and **re-run that check to
confirm green** before moving on. Keep each fix scoped to what the check reported, and record
it (what failed, what changed) for the report and the commit message. After three attempts on
one check, record the last failure and reclassify the item as **still failing**.

**Fix the code so the check passes as written.** A path to green that runs through disabling
a lint rule, skipping or deleting a test, weakening an assertion, loosening a type, widening
a timeout, or adding an ignore comment is an **Ask first** item: surface it with the failure
and let the user decide.

**A failure that matches the intent is an Ask first item.** Check every failure against
Step 3 before fixing it: a test that fails because the PR deliberately changed the product is
working correctly. Quote the failure and the relevant intent as they actually read, and let
the user pick.

**A criterion that asks for a test gets a behavioral test.** Call the real interface and assert
what it does; grepping the implementation for a string, a name, or a config line proves
nothing, since the text could be a comment and a rename breaks the test without breaking the
product. For a regression, confirm the test fails before the fix and passes after.

**Capture evidence before calling something Manual.** For UI, page, layout, or copy items,
drive the real page with Playwright or Chrome automation when the repo has it, screenshot
it, and reference the capture in the report. When it genuinely needs a physical device, a
real purchase, a camera, or a human aesthetic call, say **which** in the report.

Every item ends the step in one of three states — green, **Ask first**, or **still failing**
with its last output captured. Fixes land in the working tree; Step 7 pushes them.

## 7. Push

Dirty tree (conflicts resolved in Step 2, or checks fixed in Step 6) → commit and push to the
PR branch, no confirmation. Leaving the PR green is the point of the run.

- Read `git status` and confirm only the run's own files are there, then stage and commit.
  Name what happened — `test: resolve merge conflicts and fix failing lint (0XC-nnn)` — and
  follow the repo's commit convention (this repo ends with a `Co-Authored-By: Claude …`
  trailer).
- `git push` to `headRefName`. After a detached fetch rather than a tracking checkout, push
  explicitly to the head ref.
- Clean tree: nothing to push. Say so.
- Rejected push (branch moved, or a fork you can't push to): report it with the local commit
  intact and leave it for the user.

## 8. Report

Every checklist item from Step 5 lands in exactly one bucket. Omit the empty ones.

```
## Test results for PR #<n> — <title>

### ✅ Automated & passing
- [x] Typecheck (`npm run …`) — clean
- [x] Unit tests — 128 passed
- [x] Paywall renders on the locked tile — screenshot: <path>

### 🔧 Fixed & pushed
- [x] Lint — 2 unused imports, removed → clean (pushed in <sha>)
- [x] Merge conflicts in `app/widget.tsx` — resolved (pushed in <sha>)

### ❓ Needs your decision
- [ ] `renders empty state` fails — the PR intentionally removed the empty state
      (ticket: "drop the empty state, show the skeleton instead"). Fixing the test means
      changing its assertion. Update the test, or was the removal a mistake?

### ❌ Still failing (couldn't fix)
- [ ] Build — <one-line reason>; needs <secret/device/decision> (3 attempts)

### 🔲 You need to test manually
- [ ] Place the Small widget on the home screen, then open the app — verify it repaints
      (couldn't automate: needs a physical device)

---
- **PR:** https://github.com/<owner>/<repo>/pull/<n>
- **Ticket:** https://linear.app/<workspace>/issue/0XC-nnn
```

One tight line per item plus a pointer, with the pushed sha on anything you changed. **Needs
your decision** items quote the failure and the intent verbatim; **Manual** items say which
thing you lacked. Close with a one-sentence verdict — "Conflicts resolved and lint fixed,
both pushed; automated checks pass; 1 decision and 2 manual items remain" — or, on a clean
run, say plainly that everything passed and nothing was pushed.

**The links block is always last**, on every run, as bare clickable URLs. With no ticket,
print the PR line and note that none is linked.

## Guardrails

This skill tests; it doesn't decide. A rejected push is reported, never forced. The PR is
never merged, closed, approved, or sent a review. A check is reported as passing only when
you watched it run to completion.

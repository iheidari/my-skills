---
name: test-task
description: Test a pull request against its own "How to test" steps. Resolves the PR (a number/URL, the current branch's PR, or — on main — the next open one), checks it out, resolves conflicts, reads the linked Linear ticket for intent, then runs every check it can automate and fixes what fails — stopping to ask before any fix that would change product behavior. Commits and pushes its fixes, then reports what passed, what it fixed, what needs a decision, and what you must verify by hand, ending with the PR and ticket links. Use when the user runs /test-task [PR], or says "test this PR", "test the task", or "run the how-to-test steps".
disable-model-invocation: true
---

# Test Task

Verify a pull request against the **"How to test"** steps its author wrote in the PR
description. Automate everything that can be automated, **fix whatever automated check
fails**, and — when the run changed the working tree (conflicts resolved or a check
fixed) — commit and push those changes back to the PR branch. Then hand the user a clean
checklist of what's confirmed, what you fixed, what needs their call, and what still needs
a human.

The skill argument is optional: a PR number (`/test-task 46`), a PR URL, or empty
(`/test-task`). With no argument it uses the current branch's PR — or, when you're on the
default branch, the next open PR. It then checks out that PR's branch and resolves any
conflicts before testing, pausing only if your current branch has uncommitted changes.

Requires the `gh` CLI.

## Workflow

### 1. Resolve the PR

Fetch the target PR's fields with
`gh pr view <target> --json number,title,body,headRefName,baseRefName,url,state,mergeable,mergeStateStatus`.

- **Argument given** (number or URL): the target is that PR. Go ahead — no confirmation.
- **No argument**: branch on where the user is (`git rev-parse --abbrev-ref HEAD`):
  - **On the default branch** (`main`/`master`): pick **the next open PR** —
    `gh pr list --state open --json number,createdAt`, take the **oldest** (earliest
    `createdAt`) — and go ahead. **No confirmation.** If there are no open PRs, say so and stop.
  - **On a feature branch with an open PR**: use that branch's PR (`gh pr view` with no arg).
  - **On a feature branch whose PR is already merged/closed**: don't retest it. Say so and
    fall through to **the next open PR** (as in the default-branch case above), no
    confirmation.
  - **On a feature branch that never had a PR**: **stop**, tell the user this branch has no
    PR, and ask what to do (test a specific PR? switch to main and take the next one?). This
    ask happens only here — never when the user is on the default branch.
- When a PR is named explicitly (argument given), a closed/merged state is fine — note it and
  continue (retesting a merged PR on request is valid). The skip-merged rule above applies
  only to the no-argument, current-branch case.

### 2. Check out the PR branch & resolve conflicts

Get the working tree onto the PR's code:

- If already on `headRefName`, skip the checkout.
- Otherwise, **the only thing that pauses this skill**: if the current branch has uncommitted
  changes (`git status --porcelain` is non-empty), **stop** and tell the user to commit or
  stash first. With a clean tree, check out the PR **automatically, no confirmation** —
  `gh pr checkout <number>` (falls back to fetching `headRefName`).
- **Resolve conflicts if the PR has any.** If `mergeable` is `CONFLICTING` (or a local merge
  of `baseRefName` conflicts), merge the base branch in and resolve — invoke the
  `resolving-merge-conflicts` skill via the Skill tool if available. **Inform the user that
  you're resolving conflicts and proceed — do not wait for confirmation.** Once resolved,
  continue to testing.

### 3. Read the ticket for intent

Find the ticket identifier (e.g. `0XC-173`) in the PR title, the PR body, or the branch name
(`headRefName`), in that order. Read the ticket with the **`linearis` CLI** —
`linearis issues read <id>` — falling back to the Linear MCP (`get_issue`) only if the CLI
isn't available. Keep two things from it:

- **What the change was meant to do** — the intent, in the ticket author's own words.
- **Its acceptance criteria** — the bar the PR is actually measured against, which is often
  wider than the author's own "How to test" steps.

**Read this before running anything.** It's the run's yardstick. Without it you can't tell
"this check failed because the code is wrong" from "this check failed because the author
deliberately changed the behavior" — and getting that backwards means silently reverting a
decision someone made on purpose, then pushing it (Step 5).

Keep the ticket's `url` for the links block in Step 8 — it's resolved here, don't look it up
twice.

If there's no identifier anywhere, or Linear isn't reachable, say so and carry on — the run
is still valid, just with less context. **Never invent a ticket or a URL.**

### 4. Extract the "How to test" section

From the PR `body`, find the section whose heading matches **how to test** (case-insensitive;
also accept "Testing", "Test plan", "QA", "How to verify"). Take everything from that heading
until the next heading or end of body.

- If no such section exists, **fall back to the acceptance criteria** from the ticket in
  Step 3 and build the checklist from those instead — say that's what you're doing.
- If there is neither a "How to test" section nor a reachable ticket, **stop** and report that
  there's nothing to build a checklist from. Show the available headings so the user can
  point you at the right one.

### 5. Build the checklist

Turn each testable step into a checklist item. Classify each item as one of three:

- **Automatable** — you can run it in the shell without a human eye, and any fix it needs is
  mechanical: install a new dependency, `typecheck`, `lint`, `format:check`, unit/integration
  tests, a build/bundle smoke check, running a script, hitting an endpoint with `curl`.
- **Ask first** — you *could* run and fix it, but the fix is a judgment call, not a mechanic:
  it would change what the product does, undo something the ticket says was deliberate, relax
  a check instead of satisfying it, or reach into code outside this PR's scope. Run the check
  to see the failure, but **don't fix it** — surface the question with the failure verbatim.
- **Manual** — needs a human, a device, or a visual judgment: "place the widget and open the
  app", "check the paywall renders", "confirm the animation is smooth", "verify on a physical
  device". Before putting anything here, read the evidence rule in Step 6 — some of these you
  can actually verify yourself.

**When you can't tell which bucket an item belongs in, it goes in Ask first.** An
unclassified item is never eligible for an automatic fix. Guessing "Automatable" is the
expensive mistake: it means pushing a change nobody approved.

Show the classified checklist **before** running anything, so the user sees the plan.

### 6. Run the automatable items

The working tree is already on the PR branch (Step 2). Then:

- **Detect the package manager** from lockfiles (`pnpm-lock.yaml` → pnpm, `package-lock.json`
  → npm, `yarn.lock` → yarn) or the repo's `CLAUDE.md`. Honor project conventions — e.g. this
  user's Fexi repo uses **npm** scripts, other repos use **pnpm**; never assume.
- **Install deps** if the steps call for it or `package.json`/lockfile changed in the PR
  (`gh pr diff <number> --name-only`).
- Run each automatable step and **capture the outcome** (pass/fail + the key output lines).
  Run the safe read-only checks (typecheck, lint, tests) even if a step is vaguely worded —
  they're cheap signal. Run formatters/writes only if the step explicitly asks.
- If a step is destructive, irreversible, or outward-facing (deploys, publishes, deletes,
  hits production), **do not run it** — mark it manual and say why.

**Fix what fails — three attempts, then stop.** When an automated check fails, diagnose and
fix it, then **re-run that check to confirm it's green** before moving on. Keep fixes tight
and scoped to what the check reported — don't refactor beyond the failure. Record each fix
(what failed, what you changed) so the report and commit message can name it. **After three
attempts on the same check, stop**: record the last failure and reclassify the item as "still
failing". Don't keep cycling — an unbounded fix loop burns the run and leaves a mess behind.

**Fix the code, never the check.** Making a check pass by making it check less is not a fix:
never disable or reconfigure a lint rule, delete or `skip` a failing test, weaken an
assertion, loosen a type, widen a timeout, or add an ignore comment to reach green. If the
only way past a failure is to make the check weaker, that's an **Ask first** item — surface
it, don't do it. Never fake a green.

**If a fix would change behavior, stop and ask.** Compare the failure against the intent from
Step 3. A test that fails because the PR deliberately changed what the product does is not a
bug to fix — "fixing" it reverts the author's decision. Move the item to **Ask first**, quote
the failure and the relevant intent as they actually read, and let the user decide. Don't
paraphrase the detail away or pre-judge the answer.

**If a step asks you to write a test, test behavior, not source text.** A test whose only
evidence is grepping the implementation for a string, a function name, or a config line
proves nothing — the text could be a comment or dead code, and a harmless rename breaks the
test without breaking the product. Call the real interface and assert what it actually does.
For a regression, confirm the test fails before the fix and passes after it.

**Capture evidence before calling something manual.** For UI, page, layout, or copy items,
try to verify them yourself first — drive the real page with Playwright or Chrome automation
if the repo has it, and take a screenshot or capture the rendered output. Reference what you
captured in the report. If you genuinely can't (needs a physical device, a real purchase, a
camera, a human aesthetic call), say **why** rather than silently punting it to Manual.

If a failure is genuinely outside your reach (needs a device, a secret, an outward-facing
call, or a product decision), leave it unfixed, capture why, and reclassify it.

Every fix lands in the working tree; the changes are committed and pushed in Step 7.

### 7. Push the changes

If the run left the working tree dirty — conflicts resolved in Step 2, or checks fixed in
Step 6 — **commit and push to the PR branch, no confirmation** (the whole point of this
skill is to leave the PR green):

- Stage and commit only the files the run touched (`git add -A` **after** reading
  `git status` and confirming nothing unexpected is there). Write a message that names what
  happened — e.g. `test: resolve merge conflicts and fix failing lint (0XC-nnn)` — and follow
  the repo's commit-message convention (this repo ends the trailer with
  `Co-Authored-By: Claude …`).
- Push to the PR's `headRefName` (`git push`). If the checkout was a detached fetch rather
  than a tracking branch, push explicitly to the head ref.
- If the tree is **clean** (every check passed first try and there were no conflicts), there
  is nothing to push — skip this step and say so.
- If a push is rejected (branch moved, or the PR is from a fork you can't push to), stop and
  report it with the local commit intact — don't force-push.

### 8. Report

Present the final checklist grouped into buckets:

```
## Test results for PR #<n> — <title>

### ✅ Automated & passing
- [x] Typecheck (`npm run …`) — clean
- [x] Lint — 0 errors
- [x] Unit tests — 128 passed
- [x] Paywall renders on the locked tile — screenshot: <path>

### 🔧 Fixed & pushed
- [x] Lint — failed on 2 unused imports, removed them → clean (pushed in <sha>)
- [x] Merge conflicts in `app/widget.tsx` — resolved (pushed in <sha>)

### ❓ Needs your decision
- [ ] `renders empty state` test fails — the PR intentionally removed the empty state
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

Omit any empty bucket. Keep each detail line tight (one line + a pointer), note the pushed
commit sha for anything you changed, and end with a one-sentence verdict (e.g. "Conflicts
resolved and lint fixed, both pushed; automated checks now pass; 1 decision and 2 manual
items remain"). If nothing failed and nothing was pushed, say so plainly.

For **Needs your decision** items, quote the failure and the relevant intent verbatim. For
**Manual** items, say why you couldn't verify it yourself.

**The links block is always last.** Print the full PR and ticket URLs (bare, clickable — no
markdown link text hiding them) after the checklist and the verdict, so the user can jump
straight to either one. Include it on every run, even when everything passed and nothing was
pushed. If there's no ticket, still print the PR line and note that no ticket is linked.

## Never

Whatever the checklist says, this skill does not:

- **force-push** — a rejected push is reported, not overridden.
- **merge, close, approve, or request changes on the PR** — it tests, it doesn't decide.
- **edit files unrelated to the check it's fixing** — no drive-by refactors, no reformatting
  files the failure didn't name.
- **`git add -A` without reading `git status` first** — see what's there before staging it.
- **make a check weaker to make it pass** (Step 6).
- **push a change that alters product behavior without asking** — that's an Ask first item.
- **report a check as passing that it didn't run to completion**, or invent a ticket, a URL,
  or an outcome it didn't observe.

---
name: test-task
description: Test a pull request against its own "How to test" instructions. Resolves a PR (an explicit number/URL, the current branch's PR, or — on main — the next open PR), checks out its branch, resolves any merge conflicts, reads the "How to test" section from the PR body, turns it into a checklist, then runs every step it can automate (install deps, typecheck, lint, unit tests, build) and reports which items passed, which failed, and which the user must verify by hand (device/UI/visual). Use when the user runs /test-task [PR], or says "test this PR", "test the task", or "run the how-to-test steps".
disable-model-invocation: true
---

# Test Task

Verify a pull request against the **"How to test"** steps its author wrote in the PR
description. Automate everything that can be automated, then hand the user a clean
checklist of what's confirmed and what still needs a human.

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

### 3. Extract the "How to test" section

From the PR `body`, find the section whose heading matches **how to test** (case-insensitive;
also accept "Testing", "Test plan", "QA", "How to verify"). Take everything from that heading
until the next heading or end of body.

- If no such section exists, **stop** and report: the PR description has no "How to test"
  section — nothing to build a checklist from. Show the available headings so the user can
  point you at the right one.

### 4. Build the checklist

Turn each testable step into a checklist item. Classify each item as one of:

- **Automatable** — anything you can run in the shell without a human eye: install a new
  dependency, `typecheck`, `lint`, `format:check`, unit/integration tests, a build/bundle
  smoke check, running a script, hitting an endpoint with `curl`.
- **Manual** — needs a human, a device, or a visual judgment: "place the widget and open the
  app", "check the paywall renders", "confirm the animation is smooth", "verify on a physical
  device", anything about how something *looks* or *feels*.

Show the classified checklist **before** running anything, so the user sees the plan.

### 5. Run the automatable items

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

Do not fix failures here. This skill *tests*; it reports what it finds. If a check fails,
capture the failure and move on to the next item.

### 6. Report

Present the final checklist grouped into three buckets:

```
## Test results for PR #<n> — <title>

### ✅ Automated & passing
- [x] Typecheck (`npm run …`) — clean
- [x] Lint — 0 errors
- [x] Unit tests — 128 passed

### ❌ Automated & failing
- [ ] Build — failed: <one-line reason + where>

### 🔲 You need to test manually
- [ ] Place the Small widget on the home screen, then open the app — verify it repaints
- [ ] Check the paywall deep-link opens from the locked tile
```

Keep failing-item detail tight (one line + a pointer), and end with a one-sentence verdict
(e.g. "Automated checks pass; 2 manual items remain"). If nothing failed, say so plainly.

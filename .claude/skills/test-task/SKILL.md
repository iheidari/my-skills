---
name: test-task
description: Test a pull request against its own "How to test" instructions. Resolves a PR (an explicit number/URL, or the one for the current branch), reads the "How to test" section from the PR body, turns it into a checklist, then runs every step it can automate (install deps, typecheck, lint, unit tests, build) and reports which items passed, which failed, and which the user must verify by hand (device/UI/visual). Use when the user runs /test-task [PR], or says "test this PR", "test the task", or "run the how-to-test steps".
disable-model-invocation: true
---

# Test Task

Verify a pull request against the **"How to test"** steps its author wrote in the PR
description. Automate everything that can be automated, then hand the user a clean
checklist of what's confirmed and what still needs a human.

The skill argument is optional: a PR number (`/test-task 46`), a PR URL, or empty
(`/test-task`) to use the PR for the current branch.

Requires the `gh` CLI.

## Workflow

### 1. Resolve the PR

- **Argument given** (number or URL): `gh pr view <arg> --json number,title,body,headRefName,url,state`.
- **No argument**: resolve the PR for the current branch with `gh pr view --json number,title,body,headRefName,url,state`.
  - If `gh` reports no PR for this branch, **stop** and tell the user: no PR found for the
    current branch — pass a PR number or push/open a PR first. Do not guess.
- If the PR is closed/merged, note it but continue (testing a merged PR is valid).

### 2. Extract the "How to test" section

From the PR `body`, find the section whose heading matches **how to test** (case-insensitive;
also accept "Testing", "Test plan", "QA", "How to verify"). Take everything from that heading
until the next heading or end of body.

- If no such section exists, **stop** and report: the PR description has no "How to test"
  section — nothing to build a checklist from. Show the available headings so the user can
  point you at the right one.

### 3. Build the checklist

Turn each testable step into a checklist item. Classify each item as one of:

- **Automatable** — anything you can run in the shell without a human eye: install a new
  dependency, `typecheck`, `lint`, `format:check`, unit/integration tests, a build/bundle
  smoke check, running a script, hitting an endpoint with `curl`.
- **Manual** — needs a human, a device, or a visual judgment: "place the widget and open the
  app", "check the paywall renders", "confirm the animation is smooth", "verify on a physical
  device", anything about how something *looks* or *feels*.

Show the classified checklist **before** running anything, so the user sees the plan.

### 4. Run the automatable items

First make sure the working tree is on the PR's branch (or its checked-out code) — if the
current branch isn't `headRefName`, tell the user and ask before switching. Then:

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

### 5. Report

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

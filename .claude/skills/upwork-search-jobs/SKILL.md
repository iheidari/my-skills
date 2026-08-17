---
name: upwork-search-jobs
description: Search the Upwork marketplace via the Upwork MCP for jobs posted in the last 10 days, score the top 10 on relevance, difficulty, and worth (1-10 each), and append them to a JSON ledger so reruns never re-surface the same job. Use when the user asks to find, search, scan, or check Upwork for new jobs, wants a shortlist of jobs worth applying to, or runs upwork-search-jobs. For assessing or writing a proposal for one specific job, use upwork-application instead.
---

# Upwork Job Search

Finds jobs Iman hasn't seen yet, ranks them, and remembers them.

**Ledger (default):** `~/Projects/upwork/jobs/upwork-jobs.json` — override with a path the user names.
**Window:** jobs with `created_date` within the last 10 days. Nothing older is ever reported.
**Output:** exactly 10 new jobs (fewer only if the marketplace genuinely has fewer), ranked.

## Workflow

1. **Load seen ids** — `node scripts/store.mjs seen` (path relative to this skill dir). Returns a JSON array of job ids already in the ledger. Never re-report those.
2. **Get org_uid** — `upwork__list_accounts`, take the `TALENT` account's `org_uid`.
3. **Search** — `upwork__find_jobs action=search` with `sort: "recency"`, `limit: 10`, `verified_payment_only: true`. Run the query set below, one call per query. There is **no date filter in the API** — paginate with `cursor` (from `pageInfo.endCursor`, only while `hasNextPage`) and stop a query as soon as results pass 10 days old. Cap the whole run at ~25 search calls.
   Queries (run in order, stop early once ~40 unseen in-window candidates are pooled):
   `react native` · `next.js` · `full stack developer` · `node.js api` · `mobile app developer` · `react dashboard` · `graphql` · `existing codebase fix`
   Also run `action=smart_search` once — it matches against Iman's actual profile skills.
4. **Pool and prefilter** — drop: seen ids, anything outside 10 days, and anything hitting a hard disqualifier (see [SCORING.md](SCORING.md) § Prefilter). Prefilter on the snippet alone; do not spend `get` calls on obvious skips.
5. **Enrich the finalists** — `upwork__find_jobs action=get` on the ~12–15 best-looking survivors. This is the only source of `avgRateBid`, `totalHired`/`invitesSent` (is it still open?), `preferred_qualifications`, and the client's full work history. Skip anything already hired or with invites out.
6. **Score** — apply [SCORING.md](SCORING.md) to produce `relevance`, `difficulty`, `worth`, and `overall` for each. Rank by `overall`, take the top 10.
7. **Append** — pipe the 10 records as a JSON array to `node scripts/store.mjs append`. It skips ids already present and prints how many were written.
8. **Report** — the table below, then offer to run `upwork-application` on any of them.

## Report format

```
Searched N jobs · M new in window · top 10

#  Overall  Rel  Diff  Worth  Title                        Budget      Props  Age
1  8.4      9    5     8      Rescue a broken RN app       $4,000 fx   6      2d
   https://www.upwork.com/jobs/~0212345
   One line on why it ranked here.
```

Sort by `overall` descending. One line of justification per job, naming the actual signal — not a restatement of the score. Flag any job that would rank top-3 except for a hard disqualifier; that pattern is worth knowing.

## Rules

- **Never invent a score input.** If `avgRateBid` or client hires are absent, score that dimension from what exists and say the input was missing.
- **Never re-report a seen id**, even if it now looks better. If a genuinely strong job was seen before, mention it in one line outside the table.
- **Write the ledger even on a thin run.** Two new jobs is a valid result; padding the list with stale or off-stack jobs is not.
- **Scoring alone is not a verdict.** A high `overall` is a candidate for `upwork-application`, which owns the APPLY / SKIP decision.
- **Weekly hours are not a filter.** `30+ hrs/week` does not disqualify a job here; only employment-shaped work does (see [SCORING.md](SCORING.md) § Prefilter).
- Full profile and hard disqualifiers live in the `upwork-application` skill — that is the source of truth for fit. [SCORING.md](SCORING.md) carries only the compact version.

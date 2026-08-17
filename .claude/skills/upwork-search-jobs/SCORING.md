# Scoring

Three independent 1–10 scores plus a weighted `overall`. Score each dimension on its own — do not let a great budget inflate relevance, or a hard job depress worth.

## Prefilter (before spending `get` calls)

Drop outright:

- `engagement` is `30+ hrs/week`, or the post says full-time / part-time role / "join our team" / contract-to-hire
- Requires daily standups, fixed working hours, or heavy timezone overlap
- Fixed budget under $800, or a stated hourly range topping out under $45
- Stack Iman doesn't work in: WordPress or Shopify theme work, pure design, pure ML research, Salesforce, SAP, .NET, legacy PHP, game engines
- Fundamentally no-code automation (n8n / Make / Zapier) with no real engineering
- Client `verification_status` is not `VERIFIED`
- Client has many posted jobs and zero hires

Everything else survives to `get`.

## Relevance (1–10) — how well it matches Iman's skills

Iman: senior full-stack — React · React Native · Node · REST/GraphQL · Postgres/Mongo · CI-CD · web, iOS, Android, desktop. Industries: fintech, dating/social, retail/e-commerce, IoT, blockchain.

| Score | Meaning |
|---|---|
| 9–10 | Core stack is the whole job (RN app, React+Node build, API work) **and** an industry match or a rescue/refactor shape |
| 7–8 | Core stack is the whole job, neutral industry |
| 5–6 | Adjacent — mostly his stack with one significant unfamiliar piece |
| 3–4 | Half the job is outside his stack |
| 1–2 | Barely overlaps; would have been a prefilter drop if it were clearer |

Bonuses worth +1 each (cap at 10): existing codebase / previous dev left / something broken; a business metric attached (revenue, performance, conversion); explicitly fixed-price with a defined deliverable.

## Difficulty (1–10) — how hard to deliver, 10 hardest

Judge scope × unknowns × compliance surface, at ~20 hrs/week capacity.

| Score | Meaning |
|---|---|
| 1–3 | Days of work. Bug fix, single integration, small feature on an existing app |
| 4–6 | 2–5 weeks. A defined app or API build, known stack, clear spec |
| 7–8 | 6+ weeks, or genuine unknowns: undocumented legacy, hard performance targets, multi-platform, heavy compliance (PII, payments, health) |
| 9–10 | Research-grade, or scope that can't be bounded from the post |

Difficulty is **not** a penalty. Report it so the estimate is honest. In `overall` it is mildly negative only past 7.

## Worth (1–10) — how much this is worth applying to

Score each input, then average with the weights shown. Missing input → drop it and renormalize, and say so in the report.

| Input | Weight | 10 | 5 | 1 |
|---|---|---|---|---|
| **Client spend proxy** — `client.total_hires` × contract sizes in `client_work_history`; long ACTIVE hourly contracts and repeat hires read as heavy spend | 30% | 20+ hires, several long/large contracts, rating 4.8+ | ~5 hires, mixed small contracts | 0–1 hires, or all tiny fixed jobs |
| **Money on this job** — fixed `budget`, or `avgRateBid`/`maxRateBid` from `get` when the post states no rate | 30% | Fixed $5k+, or bids averaging $70+/hr | Fixed ~$2k, or bids ~$45/hr | Fixed <$1k, or bids under $25/hr |
| **Competition** — `proposal_count` | 20% | 0–5 proposals | 15–20 | 50+ |
| **Freshness** — now − `created_date` | 20% | < 12 hours | ~4 days | 9–10 days |

Hard caps regardless of the average:

- Any `totalHired > 0` or `invitesSent > 0` → worth ≤ 3 (likely already gone)
- `preferred_qualifications.min_job_success_score` set and Iman has no JSS yet → worth ≤ 6
- Fixed budget under $1,500 → worth ≤ 5

## Overall

```
overall = 0.45 × relevance + 0.45 × worth − 0.10 × max(0, difficulty − 7)
```

Round to one decimal. Ties break toward fewer proposals, then toward fixed-price.

## Ledger record shape

Each object appended to the JSON ledger:

```json
{
  "id": "2089255129103573973",
  "title": "Full-Stack Next.js Developer",
  "url": "https://www.upwork.com/jobs/~02...",
  "job_type": "hourly",
  "budget": "0.0",
  "hourly_avg_bid": 28.6,
  "proposal_count": 38,
  "created_date": "2026-08-17T07:36:54+0000",
  "client": { "country": "Germany", "rating": 5, "total_hires": 21, "verified": true },
  "skills": ["Next.js", "TypeScript"],
  "scores": { "relevance": 7, "difficulty": 6, "worth": 5, "overall": 5.4 },
  "note": "Strong stack match but 38 proposals and no stated rate.",
  "found_at": "2026-08-17"
}
```

`id` is the dedupe key. `found_at` is the run date, so a later run can tell how long a job has been on the list. The script stamps `found_at` if omitted.

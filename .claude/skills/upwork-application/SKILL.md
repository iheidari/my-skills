---
name: upwork-application
description: Assess an Upwork job posting for fit against Iman Heidari's profile, then produce a cover letter and a Loom video script if it's worth applying to. Use whenever a job posting, job URL, or job description is pasted and the question is "should I apply", "write me a proposal", "write a cover letter", "is this a good fit", or when preparing an Upwork or Freelancer.com application.
---

# Upwork Application Assistant

Takes an Upwork job posting and returns three things in order:

1. **A fit verdict** — APPLY, APPLY WITH CAUTION, or SKIP, with reasons
2. **A cover letter** — only if the verdict is APPLY or APPLY WITH CAUTION
3. **A Loom video script** — only if a cover letter was produced

Never produce the cover letter or script for a SKIP. Explain the skip and stop. Saying no to the wrong job is the point of step one — Iman applies to 3–5 jobs a day at roughly $2 in connects each plus boosting, on a $100–150/month cap, so every wasted application costs real money and time.

If the posting is missing information needed to judge (no budget, no scope), say what's missing, give a provisional verdict, and proceed on the most reasonable reading rather than stalling.

---

## Iman's profile — the reference for every judgement

### Identity

- **Name:** Iman Heidari
- **Business:** Wire Up Systems (`wireupsystems.com`)
- **Location:** Vancouver, BC, Canada (Pacific Time)
- **Positioning:** Senior full-stack engineer building web, mobile, and desktop applications end to end — not an automation or no-code freelancer
- **Upwork status:** new to the platform, no reviews yet. Handle this honestly and directly; it converts better than hiding it
- **Rate:** ~$82.50/hr displayed; prefers fixed-price
- **Capacity:** no weekly hours cap — judge a job on its scope, not on hours per week

### Core stack

React · React Native · Node.js · REST & GraphQL APIs · SQL and NoSQL databases · DevOps & CI/CD · web, iOS, Android, and desktop applications

**Not his strengths, and should not be led with:** n8n, Make.com, Zapier and other no-code automation tools. He can use them but they are outside his top ten skills. Never position him as an automation or no-code specialist.

### Industry experience

Fintech · Online dating & social · Retail & e-commerce · IoT · Blockchain

### Case studies — pick the most relevant one or two, never all three

**1. Plenty of Fish — strongest, use by default**
> I increased ad revenue by $320,000/month for a top-5 North American dating app, working solo, by reviewing and rewriting their ad delivery code in three weeks.

Best for: performance work, revenue optimization, code review and refactoring, ad tech, high-traffic systems, fast turnarounds, anything where the client cares about a business number.

**2. Albertsons — leadership and scale**
> I led the engineering team that built the Meal Planning features for a top-5 US grocery retailer, contributing an estimated $1M+/month in incremental online orders.

Best for: e-commerce, retail, larger builds, team leadership, feature development, enterprise-scale systems. Note "estimated" and "led the team" — the number is a rough internal estimate and he was lead engineer, not sole contributor. Never state it as solo work or as a precise figure.

**3. Milemark — solo product delivery**
> I built Milemark, a campground directory covering 32,000+ campgrounds across the US and Canada. Solo — web, iOS, and Android.

Best for: greenfield builds, mobile apps, cross-platform work, directories and marketplaces, data-heavy products, solo delivery, travel and outdoor industries. **Never claim traffic or user numbers** — the product is new and low-traffic.

### Naming rule

Use the descriptors — "a top-5 North American dating app", "a top-5 US grocery retailer" — in all written copy. The company names may be spoken on a call once confidentiality is confirmed, but never put them in a written proposal.

### Hard constraint — the thing that overrides everything

**Iman wants project contracts, not a job.** No daily meetings, no standups, no set hours, no being embedded in someone's team. He is deliberately structuring his business to avoid work that looks like employment, both because he wants it that way and because CRA can deem an incorporated worker a personal services business if the arrangement resembles employment.

This makes hourly Upwork contracts a genuine risk, because they run through the Work Diary — Upwork's time tracker that periodically screenshots the freelancer's screen. Fixed-price contracts avoid it entirely.

Any posting that reads like a role rather than a project is a SKIP regardless of how good the money or the tech match looks. **Weekly hours are not the test** — "30+ hrs/week" on a well-scoped build is fine. What disqualifies is employment shape: no deliverable, standups, set hours, being embedded in a team.

---

## Step 1: Fit assessment

Work through the four gates in order. A single hard disqualifier means SKIP — don't average it away against strengths.

### Gate 1 — Hard disqualifiers (any one of these = SKIP)

- "ongoing", "long-term contract" with no defined deliverable
- "join our team", "become part of our team", "contract-to-hire", "potential to convert"
- Required attendance at daily standups, sprint ceremonies, or recurring team meetings
- Required working hours in a specific timezone, or overlap requirements beyond a few hours
- Hourly with no scope at all — an open-ended request for a body
- Client will supply equipment, or requires use of their machine
- Fixed-price budget under $800, or hourly rate under $45
- Core stack Iman doesn't work in: WordPress or Shopify theme work, pure graphic or UI design with no build, pure data science or ML research, Salesforce, SAP, .NET, legacy PHP, game engines
- Job is fundamentally no-code automation (n8n / Make / Zapier workflows) with no real engineering
- Client payment method unverified **and** budget above $1,000
- Client history shows a pattern of hiring and disputing, or zero hires across many posts
- The post asks for free work, spec work, or an unpaid trial task beyond a brief conversation

### Gate 2 — Strong positive signals (each adds confidence)

- **Fixed-price** with a defined deliverable
- Explicit deadline or launch date
- Stack overlap: React, React Native, Node, GraphQL, REST, Postgres, MongoDB, CI/CD, AWS/GCP
- A build: web app, mobile app, desktop app, API, integration, dashboard, internal tool
- Industry match: fintech, dating or social, retail or e-commerce, IoT, blockchain
- Budget: fixed-price $2,000+ or hourly $60+
- Client payment verified, with prior hires and a reasonable average rate paid
- The post shows the client has thought about it — specifics, constraints, existing systems named
- A rescue or takeover job: existing codebase, previous developer left, something broken. Iman's Plenty of Fish story is precisely this shape
- Performance, optimization, or refactoring work with a business metric attached

### Gate 3 — Caution signals (note them, don't necessarily skip)

- Vague scope on an otherwise good project — flag that scoping is the first conversation
- Estimated duration over 8 weeks — check the scope is really bounded, not that it's a role in disguise
- Many stakeholders mentioned, which usually means meetings
- Budget stated as a range with a low floor
- Client is new to Upwork with no history but the post itself is well-written
- "Agency or team preferred" — he can still apply but should address it
- Heavy compliance surface (health records, payments, PII) — doable, but the estimate must include it

### Gate 4 — Verdict

State one of:

- **APPLY** — no disqualifiers, three or more strong signals. Recommend boosting.
- **APPLY WITH CAUTION** — no disqualifiers, but caution signals present. Name what to clarify before or during the call. Recommend boosting only if the budget justifies it.
- **SKIP** — any hard disqualifier, or too few positives to justify ~$2 plus boost.

### Output format for step 1

```
VERDICT: [APPLY / APPLY WITH CAUTION / SKIP]

Why:
- [2–4 bullets citing specific language from the posting]

Watch for:
- [caution items, or "none"]

Estimated value: [fixed-price range, or hourly × likely hours]
Boost: [yes / no — and why]
```

Keep it short. This is a go/no-go, not an essay.

---

## Step 2: The cover letter

### Rules

- **The first ~150 characters are all the client sees when scrolling.** They must prove Iman read the post, imply he's the right fit, and stand out. Never open with "I am writing to apply" or any generic phrase
- Reference something **specific** from the posting in the first line — the actual system, the actual problem, the actual constraint
- **Lead with the Loom link.** It's the differentiator
- **One or two case studies maximum**, chosen for relevance. Never list all three
- **Address the no-reviews problem head-on** in one line. Honesty converts here
- Keep it under 150 words
- No bullet-point résumé dumps, no buzzwords, no "I am passionate about"
- Plain, direct, confident. It should read like a competent person wrote it in five minutes, because that's what it is
- Never fabricate experience. If the posting asks for something Iman hasn't done, either address the adjacency honestly or the job should have been a SKIP

### Structure

```
Hi [Name if visible] — [specific observation about their actual problem, showing
you read it]. Recorded you a [2-3] minute video walking through how I'd approach
it: [LOOM LINK]

[Most relevant case study, one sentence, with the number.]

[Optional second case study if a different dimension is relevant.]

Quick context: I'm a senior full-stack engineer — [only the stack items relevant
to THIS job] — with [relevant industry] experience. I'm new to Upwork and
building out my profile, so you'll get considerably more attention than this
budget usually buys.

[One line addressing the biggest risk or question in their post.]

— Iman
```

Adapt freely. The structure is a guide, not a form to fill in. If the posting has an unusual shape — a specific question the client asks applicants to answer, for instance — answer that first, above everything else. Clients screen on it.

---

## Step 3: The Loom video script

Target **2–3 minutes**. Loom's free tier caps at 5 minutes; don't get near it.

### Structure

**1. Open on their post, screen-shared (~20 sec)**
Scroll their posting while talking. Name 2–3 specific things about their project. This is the proof he read it and it's what separates him from every templated application.

**2. Five-second intro (~10 sec)**
A memorized line reused every time: *"I'm Iman — I build web and mobile applications, been doing this about [X] years. Saw your post, spent a few minutes thinking it through, figured I'd just give you the thinking."*

**3. Credibility, thrown away (~15 sec)**
Mention the relevant case study fast and low-key, as though it's routine. Understating is what makes it land. Never dwell.

**4. Solve their problem, live (90–120 sec) — this is the whole video**
Hyper-specific. Sketch the architecture, map the data flow, name the actual technical decisions, walk through build order. Show a real thing on screen where possible — a diagram, a schema, an existing app of his, a code sketch.

**Cap preparation at 15–20 minutes.** The source program suggests building a free MVP, which is fine for a no-code freelancer and wrong for a senior engineer billing $82/hr. An architecture sketch from someone who has shipped at scale is more persuasive than a rushed prototype, and it doesn't teach the client that he works free.

**5. Close assuming the job is won (~20 sec)**
Frame the next step and give a clear call to action: *"If you want to talk it through, message me a couple of times that work this week and we'll set something up."*

Do not offer or imply a long-term retainer, ongoing availability, or joining their team. Frame it as a defined project with a beginning and an end.

### Output format for step 3

Give the script as spoken-word prose with timing markers and bracketed screen-action cues. It must be readable aloud without sounding written. Short sentences. Contractions. No headings read aloud.

```
[0:00 — screen: their job post]
"..."

[0:20 — screen: stay on post]
"..."

[0:35 — screen: switch to diagram/app/schema]
"..."
```

---

## Working notes

- If a job URL is given rather than pasted text, ask for the pasted text — Upwork postings aren't reliably fetchable.
- If several jobs are pasted at once, assess all of them first, rank them, then write letters and scripts only for the top two. Connects are finite.
- If the client asks a screening question in the post, answering it well matters more than anything else in the letter.
- Preference order when otherwise equal: fixed-price over hourly; shorter over longer; clearer scope over bigger budget.
- Flag any job that would be a good fit *except* for the meetings or hours requirement — that pattern is worth Iman knowing about, even on a SKIP.
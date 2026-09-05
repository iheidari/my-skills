---
name: seo-geo-aeo
description: >
  Audit a website for SEO, GEO (AI search engines like Perplexity and ChatGPT Search),
  and AEO (featured snippets, voice search), then deliver a scored DOCX/PDF report.
  Use when the user gives a URL or domain and asks about search rankings, AI-search
  visibility, meta tags, schema markup, or asks to audit their site.
---

# SEO / GEO / AEO audit

Crawl a site, score it on three dimensions, and hand back a client-grade report document.

**Evidence** is the rule the whole audit runs on: every finding names a page you actually fetched and quotes what you found there. A signal counts as absent only once you have crawled the pages that would carry it. Found a Team page at `/team`? Say so, and score its quality. Generic advice that would fit any website is a failed finding.

## Step 1: Pick the tier

Ask before fetching, every time:

> "Would you like a **Quick Audit** (top priority issues and scores — 1-2 minutes) or a **Full Audit** (comprehensive analysis across all dimensions — 5-10 minutes)?"

Proceed straight to Step 2 only when the user's message already names a tier ("do a full audit of…", "quick audit please"). Otherwise wait for the reply.

**Done when:** the tier is Quick or Full.

## Step 2: Crawl

Fetch the given URL first with WebFetch: *"Return the complete raw HTML of this page including all meta tags, schema markup, heading structure, link elements, navigation menus, and body content."*

From that response build the **inventory** — the list of every page that exists. Source it from three places, fetched in parallel:

- links in `<nav>`, header, and footer, plus any same-domain link in the body
- `{domain}/robots.txt` — crawl directives and the sitemap pointer
- `{domain}/sitemap.xml` — catches pages missing from the nav

Then fetch pages from the inventory in parallel, in this priority order:

1. About / Team / Our Story — E-E-A-T, author signals, credentials
2. Services / What We Do / Solutions — content depth, keyword coverage
3. Case Studies / Portfolio / Work — social proof, trust signals
4. Blog / Resources / Insights — the index page *and* individual recent posts
5. Contact / Location — NAP data, local signals
6. FAQ / Help — AEO signals
7. Individual service or product pages
8. Everything else in the inventory that looks content-rich

**Quick Audit:** homepage plus the top 6 highest-signal pages.

**Full Audit:** the whole inventory. Skip only pages that carry no signal — Privacy Policy, Terms, login/account, thank-you pages, and archive pagination past page 2 — and record the skip reason for each.

When the primary URL fails to load, tell the user, ask them to confirm it is publicly reachable, and offer a framework audit meanwhile. When a secondary page fails, log the failure as a finding and carry on.

**Done when:** every URL in the inventory is marked fetched, skipped-with-reason, or failed-to-load. That accounting is the Pages Audited table later, so keep it as you go.

## Step 3: Score the signals

Work the full checklist in [`SIGNALS.md`](SIGNALS.md) — every signal, across every page you fetched, in all three dimensions.

Score each dimension 1-10:

| Score | Meaning |
|---|---|
| 1-3 | Critical — the site is likely invisible in this dimension |
| 4-5 | Below average — significant missed opportunities |
| 6-7 | Decent foundation — specific improvements needed |
| 8-9 | Strong — minor refinements available |
| 10 | Exemplary — model implementation |

Score what the evidence shows. A healthy site earns high marks; say so plainly rather than manufacturing problems to fill the report.

**Done when:** every signal in `SIGNALS.md` has a verdict backed by a named page, and all three dimensions have a score.

## Step 4: Brief the user in chat

The chat message orients the user while the document builds. Keep it to this shape — the signal-by-signal detail belongs in the report:

```
## 🔍 [Site Name] — [Quick/Full] SEO/GEO/AEO Audit

**Pages reviewed:** [count and list]  **Audit date:** [date]

| Dimension | Score | Status |
|---|---|---|
| SEO | X/10 | [Needs Work / On Track / Strong] |
| GEO | X/10 | ... |
| AEO | X/10 | ... |

**Top 3 priorities:** [one specific sentence each]

**Biggest strength:** [one sentence]

*Full findings, signal-by-signal analysis, and the priority recommendations matrix are in the report below.*
```

When the user seems new to the terms, add one sentence each explaining GEO and AEO in plain English.

Then say: "Generating your downloadable report now…"

## Step 5: Build the report

Follow [`REPORT.md`](REPORT.md) — output location, the docx setup, the design system, and the section-by-section build. Produce it without asking; the user already opted in by requesting the audit.

The document is the deliverable the user keeps, so it earns its download: full visual design, specific evidence in every table, and detail the chat recap deliberately left out.

**Done when:** the DOCX exists on disk, the PDF exists or its absence has been explained, and both paths are posted as clickable relative markdown links.

## Step 6: Offer the next move

> "Would you like me to go deeper on any specific area? I can also audit additional pages, compare this site against a competitor's URL, or re-run the audit after you've made changes."

## Assessing honestly

Some signals sit outside what an HTML fetch can reach: Core Web Vitals, real page speed, mobile rendering, JavaScript-rendered content, backlink profile, domain authority. Name the tool that measures each one instead — "for Core Web Vitals, run pagespeed.web.dev" — and leave it out of the scores.

---

*Adapted from the [SEO-GEO-AEO-Skill](https://github.com/SNLabat/SEO-GEO-AEO-Skill) by Alex Labat.*

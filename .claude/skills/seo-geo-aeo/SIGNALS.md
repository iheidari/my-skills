# Signal checklist

The reference for Step 3 of [`SKILL.md`](SKILL.md). Every signal below gets a verdict — Good, Needs Attention, or Missing — backed by a named page from the crawl. Judge each one across the whole crawl, not the homepage alone: a signal is Missing only when none of the pages you fetched carry it.

## SEO — traditional search engines

**Technical on-page**

- **Title tag** — present? 50-60 chars? primary keyword? compelling? duplicated across the site?
- **Meta description** — present? 150-160 chars? carries a CTA? engaging?
- **Heading hierarchy** — one H1? H2/H3 logical and keyword-relevant? any stuffing?
- **URL structure** — readable, keyword-bearing, free of stop words and parameter sprawl?
- **Canonical tag** — present and self-referencing where it should be?
- **Robots meta** — indexable, with no accidental `noindex`?
- **Viewport meta** — present for mobile?
- **Image alt text** — descriptive and relevant on the images that carry meaning?
- **Internal links** — present, with descriptive anchor text?
- **Open Graph / Twitter Card** — og:title, og:description, og:image present and share-worthy?

**Content quality**

- **Word count** — 500+ on most pages, 1500+ on pillar content?
- **Keyword signals** — primary topic established, semantically related terms present?
- **Freshness** — publication or update dates visible?
- **Readability** — scannable via subheadings, short paragraphs, bullets?

**Structured data**

- **Schema markup** — JSON-LD or microdata present? Which types (Organization, LocalBusiness, Article, Product, FAQ, HowTo, BreadcrumbList)?
- **Schema validity** — syntactically correct and complete?

## GEO — generative engines

GEO targets the AI engines that synthesise answers from several sources and cite pages: Perplexity, ChatGPT Search, Google AI Overviews, Gemini. They reward clarity, authority, and factual richness.

**E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness)**

- **Author information** — named authors with visible credentials?
- **About page** — who runs the site, their background and qualifications?
- **Contact information** — phone, address, email reachable?
- **Trust signals** — testimonials, awards, certifications, press mentions?
- **Organization schema** — brand entity declared with name, logo, URL, social profiles?

**Content for AI synthesis**

- **Factual density** — specific facts, statistics, or data an engine could cite?
- **Clear claims** — core argument or value proposition stated plainly at the top?
- **Source citation** — external authoritative sources referenced?
- **Comprehensiveness** — the topic fully addressed, or key questions left hanging?
- **Entity clarity** — the brand, person, or place named consistently so engines can resolve the entity?
- **Originality** — a distinct point of view, original data, or perspective worth citing?

**Technical GEO**

- **Structured data depth** — richer types beyond the basics (Author, Dataset, ClaimReview, SpeakableSpecification)?
- **HTTPS** — secure?
- **Crawlability** — no robots.txt blocks, no JavaScript-only rendering that hides content from AI crawlers?
- **sameAs links** — outbound social profile links strengthening the entity graph?

## AEO — answer engines

AEO targets featured snippets, People Also Ask, and voice assistants, which need one extractable, concise answer.

**Featured snippet eligibility**

- **Direct answer paragraphs** — the key question answered in 40-60 words directly under a question-phrased heading?
- **Definition patterns** — the core topic defined in a clean "X is…" sentence?
- **List content** — numbered steps or bullets that could become a list snippet?
- **Table content** — comparison tables that could become a table snippet?

**Structured answer formats**

- **FAQ schema** — present, with questions and answers structured correctly?
- **HowTo schema** — step-by-step content marked up?
- **Question-phrased headings** — H2/H3s in natural question language ("How does X work?")?
- **Speakable schema** — SpeakableSpecification on voice-friendly sections?

**Voice search readiness**

- **Conversational language** — natural phrasing rather than corporate register?
- **Long-tail coverage** — specific who/what/when/where/why/how questions addressed?
- **Local signals**, where the business is local — NAP data, local schema, location mentions?

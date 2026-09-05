# Report build

The reference for Step 5 of [`SKILL.md`](SKILL.md): produce the audit as a `.docx`, and a `.pdf` when a converter exists.

## Output location

Write into `seo-audits/` in the current working directory, creating it if needed. Filename `seo-audit-{domain-with-hyphens}-{ISO-date}.docx`. Every path below is relative to the working directory — substitute the real domain and date.

## Setup

Check for `docx` and install only if it is missing, in one command:

```bash
node -e "require('docx')" 2>/dev/null || npm install -g docx
```

If the global install hits a permissions error, install locally instead:

```bash
mkdir -p ~/.claude/skills/seo-geo-aeo/.runtime && cd ~/.claude/skills/seo-geo-aeo/.runtime && npm install docx
```

then run the script with `NODE_PATH=~/.claude/skills/seo-geo-aeo/.runtime/node_modules node report.js`.

Write the complete script to `seo-audits/report.js` and execute it in the very next tool call — the whole document in one shot.

## Design system

The report should read as a premium agency deliverable: clean, modern, visually structured.

**Palette**

| Role | Hex |
|---|---|
| Navy — cover, header rule | `1B2A4A` |
| Accent blue | `2563EB` |
| Score green (8-10) | `16A34A` |
| Score amber (5-7) | `D97706` |
| Score red (1-4) | `DC2626` |
| High-priority orange | `EA580C` |
| Alternating row fill | `F8F9FA` |
| Borders | `E2E8F0` |
| Body text | `1E293B` |
| Light section fill | `EFF6FF` |
| Strengths fill | `F0FDF4` |
| Cover attribution gray | `94A3B8` |
| Cover subtitle blue | `93C5FD` |

The score colours above drive every score cell in the document — cover tiles, executive summary, and per-signal status cells alike.

**Typography** — Arial throughout. Title 36pt bold, H1 24pt bold, H2 18pt bold, H3 14pt bold, body 11pt, footer 9pt.

**Page setup** — US Letter (12240 × 15840 DXA), 1-inch margins, 9360 DXA content width.

## Sections, in order

### 1. Cover (own section, no header or footer)

Full-page navy (`1B2A4A`), everything on one page, centred, with `spaceBefore`/`spaceAfter` doing the vertical centring. Open with ~1800 DXA of navy spacer, then:

1. Site domain — white, 36pt bold, the hero element
2. "SEO / GEO / AEO Audit Report" — `93C5FD`, 18pt
3. "QUICK AUDIT" or "FULL AUDIT" — white, 11pt, 400 DXA after
4. Score tiles — a 3-column full-width table, no visible outer border, each cell filled with its score colour and generous top/bottom margins. Inside each cell, three paragraphs: dimension label (white, 10pt bold), score number (white, 36pt bold), status word — "Strong" / "On Track" / "Needs Work" (white, 9pt italic).

Close with ~1800 DXA of spacer and the attribution in `94A3B8` 9pt: audit date, then "Generated with Claude Code — SEO/GEO/AEO audit skill". Page break after.

### 2. Executive summary

H1 "Executive Summary". A single-cell table filled `EFF6FF` holding 3-5 sentences on the site's overall position — what is strong, the most urgent issue, one key opportunity, all specific to this site.

Below it, the scores table with score cells colour-filled:

| Dimension | Score | Status | Key Takeaway |
|---|---|---|---|
| SEO | X/10 | … | one line |
| GEO | X/10 | … | one line |
| AEO | X/10 | … | one line |
| **Combined** | **X/30** | | |

### 3. Pages audited

H1 "Pages Audited". Table of every page from the Step 2 accounting: URL | Page Type | Notes ("Homepage", "Missing H1", "Rich schema detected", "Skipped — Terms"). Alternating row shading.

### 4-6. Dimension analyses

One H1 per dimension with its score as a subtitle, and H2 sub-sections matching [`SIGNALS.md`](SIGNALS.md):

- **SEO Analysis** — Technical On-Page, Content Quality, Structured Data
- **GEO Analysis** — E-E-A-T Assessment, Content for AI Synthesis, Technical GEO
- **AEO Analysis** — Featured Snippet Eligibility, Structured Answer Formats, Voice Search Readiness

Each sub-section is a 3-column table: Signal | Finding | Status. The Finding cell names the page and quotes what you saw there. The Status cell is colour-filled with white text: green "Good", amber "Needs Attention", red "Missing".

### 7. Priority recommendations

H1 "Priority Recommendations". Full-width 5-column table: Priority | Issue | Dimension | Effort | Impact. Priority cells filled with white text — 🔴 Critical `DC2626`, 🟠 High `EA580C`, 🟡 Medium `D97706`, 🟢 Quick Win `16A34A`.

### 8. What's working well

H1 "What's Working Well". A `F0FDF4` table of genuine strengths, each with evidence from the crawl.

### 9. Glossary — Full Audit only

Plain-English definitions of SEO, GEO, and AEO for readers new to the terms.

### Headers and footers — every page but the cover

**Header:** site domain left, "SEO / GEO / AEO Audit Report" right, navy (`1B2A4A`) bottom border, size 8.
**Footer:** "Generated with Claude Code" left, page number right, gray top border.

## Generating

```javascript
const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
        Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
        ShadingType, VerticalAlign, PageNumber, PageBreak, TableOfContents,
        ExternalHyperlink, LevelFormat } = require('docx');
const fs = require('fs');

// ... build the sections above ...

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync('seo-audits/seo-audit-[domain]-[date].docx', buffer);
  console.log('DOCX written');
});
```

## PDF conversion, best-effort

PDF needs LibreOffice. Try it; when it is absent, ship the DOCX and tell the user how to get the PDF.

```bash
if command -v soffice >/dev/null 2>&1; then
  soffice --headless --convert-to pdf seo-audits/seo-audit-[domain]-[date].docx --outdir seo-audits/
elif command -v libreoffice >/dev/null 2>&1; then
  libreoffice --headless --convert-to pdf seo-audits/seo-audit-[domain]-[date].docx --outdir seo-audits/
else
  echo "LibreOffice not found — delivering DOCX only. To get a PDF: 'brew install --cask libreoffice' (macOS), then re-run the convert step, or open the DOCX in Word/Pages and export to PDF."
fi
```

## Delivering

Post the paths as clickable relative markdown links:

```
Your audit report is ready:
- [Download Word Doc](seo-audits/seo-audit-[domain]-[date].docx)
- [Download PDF](seo-audits/seo-audit-[domain]-[date].pdf)   ← only when the PDF was produced
```

With no PDF, link the DOCX alone and pass on the LibreOffice instructions above.

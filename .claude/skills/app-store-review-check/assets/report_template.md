# App Store Review Pre-Flight — [App Name]

**Reviewed:** [date] · **Platform(s):** [iOS/iPadOS/macOS/…] · **Inputs reviewed:** [description / metadata / screenshots / code / ASC API]

> This is a best-effort audit against the App Store Review Guidelines, not an official Apple decision. The App Review team makes the final call.

## Overall verdict

**[ Ready to submit | Fix before submit | Not ready ]**

- 🔴 Blockers (Likely rejection): [n]
- 🟠 Risks (At risk): [n]
- ⚪ Needs info: [n]

One-paragraph summary of the biggest issues and whether the app is close.

## Findings by section

For each relevant guideline. Omit sections that don't apply (state which and why).

### 1. Safety
| Guideline | Verdict | Evidence | Fix |
|---|---|---|---|
| 1.x Title | 🔴/🟠/🟢/⚪ | what triggered it | concrete change |

### 2. Performance
| Guideline | Verdict | Evidence | Fix |
|---|---|---|---|

### 3. Business
| Guideline | Verdict | Evidence | Fix |
|---|---|---|---|

### 4. Design
| Guideline | Verdict | Evidence | Fix |
|---|---|---|---|

### 5. Legal
| Guideline | Verdict | Evidence | Fix |
|---|---|---|---|

## Prioritized fix checklist

Ordered by severity — do the blockers first.

1. [ ] **[Guideline #]** — [action]
2. [ ] **[Guideline #]** — [action]

## Not applicable / not assessed

- [Guideline area] — N/A because [reason]
- [Guideline area] — couldn't assess; provide [input] to check.

## Reviewer notes to prepare for App Store Connect

Draft "Notes for Review" content that would help a real reviewer (demo account,
explanation of the business model, how to reach gated features, licensing docs, etc.).

Include, where they apply:

- **Where each system permission prompt appears** and what triggers it — the exact
  taps from a cold launch. A reviewer who can't find a prompt rejects under 2.1
  rather than hunting for it.
- **A screen recording from a physical device** for any app linking
  AppTrackingTransparency: fresh install (or tracking permissions reset), the prompt
  appearing before any tracking data is collected, and the flow that follows. Apple
  asks for this by name on an ATT 2.1 rejection; supplying it up front pre-empts the
  round-trip. Note that the prompt is once-per-install and is **not** reset by
  deleting the app — say so in the notes, so a reviewer who already answered it on an
  earlier build knows why they won't see it again.
- **Any surface gated by purchase, entitlement, or region**, with how to reach it.

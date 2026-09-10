---
name: reviewing-a11y
description: Review accessibility of web pages, code implementations, and design mockups, then report severity-ranked issues and fixes against WCAG 2.2 and WAI-ARIA. Use when asked to check, audit, or review a11y/accessibility of a URL, component/file, or Figma/design.
argument-hint: URL, file path, or Figma URL to review
allowed-tools: Read, Grep, Glob, WebFetch, Task
---

# Accessibility Review

Review against WCAG 2.2 and the WAI-ARIA APG. Every finding rests on **evidence** you actually observed; everything you could not observe is named as unverified rather than guessed at.

## Step 1: Pick the guide

One target, one guide. Read it before reviewing.

| Target | Guide |
|---|---|
| Live URL | [`references/page-review.md`](references/page-review.md) |
| Source files, components, templates | [`references/code-review.md`](references/code-review.md) |
| Figma URL, mockup image, PDF, design spec | [`references/design-review.md`](references/design-review.md) |

When the target is ambiguous, ask which of the three the user means. When the user names several targets, run each guide in turn and merge the findings into one report.

## Step 2: Gather evidence and review

Follow the guide. It tells you how to reach the target and what that medium exposes.

Done when every element in scope is accounted for — cited in a finding, named as a good practice, or listed for manual verification. Cover interactive elements, images, form fields, headings and landmarks, and each state the target defines (focus, error, disabled, expanded).

## Severity

- **Critical** — blocks access outright: no keyboard path, missing accessible name on a control, broken ARIA ID reference, color-only error state.
- **Major** — reachable but a real barrier: low contrast, `div` with `onClick`, wrong role, broken heading hierarchy, icon-only control.
- **Minor** — works, could be better: redundant ARIA, sub-optimal element choice, line height under 1.5.

## Report shape

Open with scope: what you reviewed, and how you reached it (accessibility tree, HTML source, file read, Figma fetch). Name what the medium hid from you.

Then good practices, then findings ordered Critical → Major → Minor, each as:

```
- **Location**: file:line, CSS selector, or frame name
- **Evidence**: the code, attribute, or measurement observed
- **Issue**: what is wrong
- **WCAG**: 2.1.1 Keyboard (A)
- **Impact**: who is affected and how
- **Fix**: the corrected code or concrete change
```

Close with **Manual verification**: every check the medium could not settle, as a list a human can work through — exact contrast ratios, full keyboard flows, live-region announcements, focus movement across dynamic interactions.

## Principles

- Cite the artifact: file paths with line numbers, CSS selectors, frame names, hex values.
- Give the fixed code, not the instruction to fix.
- Defer to the HTML Standard, WCAG 2.2, and the ARIA APG over invention.
- No ARIA beats bad ARIA: flag ARIA that overrides working native semantics.
- A check the medium could not settle belongs in Manual verification, at any severity.

## Standards

- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- WCAG quick reference: https://www.w3.org/WAI/WCAG22/quickref/
- WAI-ARIA APG: https://www.w3.org/WAI/ARIA/apg/

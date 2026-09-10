# Design review

Reviewing design intent before it is built: Figma, mockups, PDFs, specs. Severity, report shape, and principles live in [`../SKILL.md`](../SKILL.md).

## Reach the design

Fetch the Figma URL or read the image, PDF, or spec. Establish what the screen does and which flows it serves, list the interactive elements, and note which states are drawn — default, hover, focus, active, disabled, error. A state that is not drawn is itself a finding.

## What to examine

- **Contrast**: text on background, and UI component and focus-indicator boundaries. Record the hex pairs; exact ratios go to Manual verification.
- **Color alone**: any state, error, or category carried by color with no text, icon, or shape.
- **Typography**: size, line height, line length, and text baked into images.
- **Touch targets**: 44×44px minimum and the spacing between neighbours.
- **Labels**: visible labels on fields rather than placeholder-only, and text on icon-only controls.
- **Focus**: whether a visible indicator is specified at all, and its contrast.
- **Responsive**: targets, scaling, and reflow at mobile widths.

## Ask, then annotate

A static design hides behaviour. Ask the design team the questions it cannot answer: where focus goes when a modal opens and closes, how the carousel responds to keyboard, what a loading state announces, what alt text each informative image carries.

Close by naming what the developer must be given to build it accessibly: ARIA roles and states per custom widget, heading levels, landmark regions, tab order for complex interactions, alt text and transcript plans.

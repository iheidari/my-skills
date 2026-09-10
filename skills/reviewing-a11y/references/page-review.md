# Page review

Reviewing a rendered web page. Severity, report shape, and principles live in [`../SKILL.md`](../SKILL.md).

## Reach the page

In priority order:

1. **Browser tooling** (a browser MCP, if one is connected) — navigate, then capture the **accessibility tree** plus the rendered view and DOM. The tree is the strongest evidence available: it carries computed roles, accessible names, and states, which is what a screen reader announces.
2. **WebFetch** — HTML source only. Blind to JS-rendered content, computed names, CSS-hidden content, and live state. Say so in the scope line and recommend a browser pass.
3. **Neither** — ask the user to paste the HTML source or attach a screenshot, and review what they give you.

## What each source settles

| Check | Accessibility tree | HTML source |
|---|---|---|
| Heading structure | computed levels | elements |
| Landmarks | computed roles | HTML5/ARIA markup |
| Image alt text | accessible names | `alt` attributes |
| Form labels | computed labels | association only |
| ARIA validity | full validation | attribute presence |
| Keyboard access | focusable order | `tabindex` only |
| Dynamic content | current state | invisible |

Anything the column marks short of full settlement goes to Manual verification.

## Work the tree

Read top to bottom. For each node: does it have a role that matches its function, an accessible name, and the states its behaviour implies? Track heading levels as you descend, and note controls with no name, generic roles on interactive nodes, and ARIA IDs pointing nowhere.

# Code review

Reviewing source: components, templates, markup. Severity, report shape, and principles live in [`../SKILL.md`](../SKILL.md).

## Reach the code

Read the target files, then identify the framework — it decides how ARIA is expressed. Grep for sibling implementations of the same widget (every button component, every modal) so a pattern found once is reported everywhere it repeats.

## What to examine

- Semantic elements and heading hierarchy.
- Accessible names: `img` `alt`, `aria-label` on icon-only controls, names computed from props.
- Forms: label association, required and invalid state, error text wiring.
- ARIA: roles, states, properties, and `aria-labelledby` / `aria-describedby` ID targets that must resolve in rendered output.
- Keyboard: handlers on non-interactive elements, `tabIndex`, focus movement on mount, open, and close.

Framework tells you where ARIA hides: React `aria-*` props and boolean values plus refs for focus; Vue `:aria-*` bindings, template refs, watchers; Angular `[attr.aria-*]` bindings and `ViewChild`.

## Beyond the findings

Where one issue repeats across files, recommend the shared fix — a focus-trap hook, an accessible icon-button wrapper, a form field with the label built in — and a test that would catch a regression.

Static source is your only evidence: computed names, rendered ARIA references, and real focus order go to Manual verification.

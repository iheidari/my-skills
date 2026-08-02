---
name: compress-claude-md
description: Compress CLAUDE.md and other always-loaded memory/rule files to minimize per-session input tokens while preserving every behavioral rule. Use when asked to compress, slim, audit, or optimize CLAUDE.md, rule files, or session context.
---

# Compress Memory Files

Reduce token cost of always-loaded context files without losing rules.

## Procedure

1. **Confirm scope.** Target file(s) from the user, or default to
   ./CLAUDE.md and ~/.claude/CLAUDE.md. Never touch skill bodies —
   they load on demand and don't pay per-turn rent.

2. **Safety.** Verify the file is committed/clean in git. If not,
   commit it first. Never compress without a restorable original.

3. **Measure before.** Count tokens (approximate: chars/4, or use a
   tokenizer if available). Record the number.

4. **Compress — deletion first, rephrasing second:**
   - DELETE: rules describing default agent behavior, explanations
     of why rules exist, duplicates across global/project files,
     instructions referencing tools or patterns no longer in use
     (flag these for confirmation, don't silently drop)
   - MOVE: rules relevant only to specific task types → suggest
     extracting to a skill (progressive disclosure)
   - REWRITE: surviving prose → terse imperatives, one line per rule
   - BYTE-PRESERVE: all code blocks, commands, file paths, URLs
   - PRESERVE EMPHASIS: rules marked NEVER/ALWAYS/IMPORTANT keep
     their emphatic phrasing verbatim — emphasis is load-bearing,
     not filler

5. **Report.** Output:
   - Before/after token counts and % saved
   - "Semantic content removed or changed" list — every deletion
     with one-line justification
   - "Flagged as possibly stale" list — needs user confirmation
   - Suggested skill extractions, if any

6. **Verify (offer, don't skip silently).** Offer to run the
   rule-equivalence check: list every behavioral rule derivable
   from old vs new version and diff the lists.

## Hard rules

- Never change what a rule requires — only how it's phrased
- Ambiguity introduced by compression = failed compression; keep
  the longer phrasing
- If a rule's purpose is unclear, flag it — do not delete
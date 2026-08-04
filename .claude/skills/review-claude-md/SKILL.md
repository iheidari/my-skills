---
name: review-claude-md
description: Audit a project's CLAUDE.md — compress it, then extract task-scoped sections into skills.
disable-model-invocation: true
---

# Review CLAUDE.md

CLAUDE.md pays **rent**: every line is re-read on every turn of every session, whether or not
the task touches it. This skill collects that rent back — first by compressing what stays,
then by relocating task-scoped material into skills that load only when they're needed.
**No behavioural rule may be lost in either half.**

## 1. Find the file

Look in the project root for `CLAUDE.md`, then `.claude/CLAUDE.md`, then `AGENTS.md`.

**If there is none, tell the developer this project has no CLAUDE.md and stop the run.** An
absent memory file is not a bug this skill fixes; authoring one from scratch is a different
job with a different conversation.

Otherwise report the path and its size in tokens (chars/4) before going on.

## 2. Compress

Invoke `compress-claude-md` (Skill tool) on that path and run it through to its report.

Done when the file is rewritten **and** the compression report is in hand. Compression is
half the job — step 3 is usually the larger win, so don't stop on a good number here.

## 3. Sort every section

Compression rewrites; extraction *relocates*. Read the compressed file heading by heading and
put each section in exactly one bucket:

- **Extract** — only some tasks need it, its trigger fits in one sentence ("before touching a
  test", "before adding a cloud provider"), and it's big enough to be worth a file (roughly
  400+ tokens). It charges rent every turn and pays out on a few.
- **Dedup** — already written in full somewhere the reader reaches anyway (`.env.example`, a
  `docs/` page, `--help` output). Delete it, point at the authority. Cheaper than extraction
  and loses nothing — check for these first.
- **Keep** — bears on most tasks (build/test commands, code conventions, the ticket system),
  or its trigger is "most work in this repo". Size alone never justifies extraction; a
  section whose violation fails *silently* (ships lint-green and build-green) stays.

A **landmine** — a rule whose violation fails far from its cause — leaves extraction only
with a pointer behind it. Skills load on description match, and a match that fails to fire on
a landmine costs hours. The pointer is emphasized and mandatory (**"IMPORTANT: load the `x`
skill before …"**), names the actions that trigger it, and lists what the skill carries, so a
reader knows what they're not currently holding.

Present the sort — every candidate with its trigger sentence, its token weight, and its
bucket — **and get confirmation before writing anything.**

## 4. Write the skills

For each confirmed extraction:

- Create `.claude/skills/<name>/SKILL.md` in the project, so the skill ships with the repo —
  unless the developer asks for user level instead.
- Move the text **verbatim**. Relocation and rewriting are separate operations; combining
  them is how a rule quietly changes meaning under cover of a move.
- Write the description to fire on the trigger you named: what the skill holds, then the
  actions that should load it ("Load this before creating or modifying …").
- Replace the moved section in CLAUDE.md with its pointer.

## 5. Verify, then report

Rules survive relocation only if you check that they did. Diff the set of backticked
identifiers and ticket references (`ABC-123`) in the original file against their union across
the new CLAUDE.md plus every file you wrote or now point at. Account for each missing one by
hand — an intentional deletion the compression report already names, or a regex artifact
where the token survives inside a longer string. **Anything you can't account for goes back.**

Then report:

- tokens before → after, and how much of the rent is cancelled
- what moved, and where it lives now
- what you deleted as duplicate, and which file owns it instead
- what you kept, and why — the keep-list is a finding, not an omission
- anything flagged stale and still waiting on the developer's call

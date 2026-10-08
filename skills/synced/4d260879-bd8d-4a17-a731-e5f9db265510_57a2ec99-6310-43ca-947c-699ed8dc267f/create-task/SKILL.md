---
name: create-task
description: Interview the user about a piece of work, then write a fully-specified task file into the tasks/ backlog. Use when the user wants to create/file/add a task, or invokes /create-task.
disable-model-invocation: true
---

Turn a rough idea into a cold-readable task file in `tasks/`. The goal is a file a future
Claude session (with **zero memory** of any conversation) can pick up and execute without
asking follow-ups. So the interview must surface every detail now.

The user's starting idea is in the skill arguments (what they typed after `/create-task`).
If empty, ask one question: "What's the task?" — then proceed.

## Step 1 — Ground it in the codebase first
Before asking the user anything, explore the repo to answer what you can yourself:
the relevant files, current behavior, related components, existing patterns. Read
`tasks/README.md` and `tasks/_template.md` so you follow the conventions. **Never ask the
user something the codebase already answers** — find it.

## Step 2 — Grill for the rest
Invoke the **grill-me** skill (via the Skill tool) to interview the user one question at a
time until the task is fully resolved. For each question, propose your recommended answer.
Drive the interview toward filling, concretely:
- **Context** — why this matters, where it lives (cite `file:line`), current behavior.
- **Goal** — what "done" looks like from the user's POV, in 1–2 sentences.
- **Acceptance criteria** — observable, checkable outcomes (include typecheck/lint/build
  gates where relevant: `pnpm --filter web exec tsc --noEmit`, `pnpm lint`).
- **Notes / constraints** — gotchas, things NOT to do, related tasks to link as `[[NNN-slug]]`.

Stop grilling once you could hand the file to a stranger and they'd know exactly what to build.

## Step 3 — Classify type & confirm priority
Once grilling is done, two frontmatter values still need to be set:

- **`type`** — one of `feature | bug | chore | refactor | docs`. **Infer it from the
  request** when it's clear (e.g. "fix X is broken" → `bug`, "add Y" → `feature`,
  "bump deps / config" → `chore`, "restructure without behavior change" → `refactor`,
  "update the README" → `docs`). If you can recognize it confidently, **set it and tell
  the user** what you picked (so they can override). If it's genuinely ambiguous, **ask**.
- **`priority`** — `high | medium | low`. **Always ask the user explicitly** for this as the
  final question, proposing a recommended level.

## Step 4 — Bundle any external assets locally
If the task references or depends on a file that isn't already in the repo — a design
handoff URL or tarball, an image, a screenshot, a spec/PDF, a sample dataset, anything a
cold reader would otherwise have to fetch — **download it into the repo now** so the task
is fully reproducible offline with zero network access:
- Fetch each file with the appropriate tool (`WebFetch`, `curl`, `Read`). If a URL returns
  an archive (gzip tarball, zip), extract it and keep the extracted files.
- These get committed under `tasks/assets/NNN-slug/` (the same `NNN`/slug the task file
  gets — the number is finalized in Step 5, so create that folder there). Stage the
  downloads now; place them when you write the file.
- In the task body, link **only the local copies** (e.g.
  `[tasks/assets/NNN-slug/foo.html](assets/NNN-slug/foo.html)`). **Never reference an
  external URL or off-repo path in the task file** — a cold reader must never need to fetch
  anything. If a source link is worth keeping for re-fetching, put it in a comment in your
  download command, not in the committed task.

## Step 5 — Write the file
1. Slug = short kebab-case from the title.
2. Build the file body first: copy the shape of `tasks/_template.md`, fill every section
   from the interview, set `status: todo`, the chosen `type:` and `priority:`, today's date
   for `created:`, leave `branch:` empty.
3. **Pick the number last, immediately before writing** — never reserve it earlier in the
   session. Compute the highest `NNN` across `tasks/` and `tasks/_done/`, add one
   (zero-padded), and write to `tasks/NNN-slug.md` in one motion. This narrows the window
   in which a second session (started around the same time) could pick the same number.
4. **Guard against collisions:** the write must not clobber an existing file. Use a
   no-overwrite write (e.g. `ls tasks/NNN-*.md` first, or a shell `set -C` / `test ! -e`
   guard) so that if `tasks/NNN-*.md` already exists, you re-read the directory, bump to the
   next free number, and retry. Only report success once the file is actually created at a
   number nothing else holds.
5. If you bundled assets in Step 4, create `tasks/assets/NNN-slug/` with the same number and
   move the downloaded files into it, then confirm the body links those local paths (and
   nothing external).

## Step 6 — Confirm
Show the path and a short summary of what you captured. Do **not** start implementing the
task — this skill only files it. Mention the user can later say "do task NNN" to execute it.

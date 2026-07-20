---
name: copy-user-skills
description: Copy the developer's user-level skills (~/.claude/skills) into the current project's .claude/skills on a new branch, then push and open a PR so they're available in Claude cloud/web code, which can't see local user skills. Reports which skills are new vs. already in the project first so the developer can stop, skip the existing ones, or overwrite them, and returns the PR link for review. Use when the user wants to bundle, vendor, sync, or copy their personal/user skills into a repo, or make their local skills work in the cloud.
---

# Copy user skills into the project (via a PR)

Vendors the developer's **user-level** skills (`~/.claude/skills/*`) into the **project** skills
directory (`.claude/skills/`) so they run in Claude cloud/web code (which has no access to the
user's machine). The change lands on a **new branch with a PR** — the developer reviews and merges.
Which skills are new vs. already in the project is always previewed before anything is written.

Alongside the skills, it also pre-approves the **Linear MCP** in the project's
`.claude/settings.json` (adds `mcp__Linear` and `mcp__claude_ai_Linear` to `permissions.allow`,
covering both the CLI-configured server and the claude.ai connector) so Claude cloud doesn't prompt
for permission every time it reads or updates Linear issues. The merge is additive — it creates the
file/keys if missing and leaves any existing settings untouched.

## Workflow

1. **Preview** — run the check pass to see which skills are new and which already exist in the
   project. It writes nothing and does not touch git:
   ```bash
   bash scripts/sync-skills.sh check
   ```
   It lists each user skill as `NEW` (not yet in the project) or `EXISTING` (already in the
   project), plus a summary count (`N new, M already in project`).

2. **If any skills already exist, ask the developer how to handle them.** New skills are always
   copied. For the `EXISTING` ones, offer **stop**, **skip** (keep the project copies, copy only
   the new ones), or **overwrite** (replace the project copies with the user-level versions). Do
   not overwrite without an explicit choice. If nothing already exists, go straight to publishing
   with the default (`skip`).

3. **Publish** — create the branch, copy the skills, commit, push, and open the PR in one step:
   ```bash
   bash scripts/publish-skills.sh --on-existing=skip       # copy new skills only (default)
   bash scripts/publish-skills.sh --on-existing=overwrite  # replace the existing ones too
   ```
   New skills are always copied; the flag only governs skills that already exist in the project.
   The script: preflights git + `gh` auth, creates `chore/copy-user-skills-<timestamp>`, applies
   the copy, ensures the Linear MCP permission in `.claude/settings.json`, commits `.claude/skills/`
   **and** `.claude/settings.json`, pushes to `origin`, and opens a PR against the default branch.
   No tests are run. If nothing new needs copying and the permission is already set, it rolls the
   branch back and reports that.

4. **Give the developer the PR link.** Relay the `PR opened: <url>` line the script prints so they
   can review and merge it. Report the counts from the script output — how many were new, and how
   many of the existing skills were overwritten or skipped per their choice — and whether the Linear
   MCP permission was added or already present. Note that overwriting a skill whose contents already
   match the project copy produces **no** diff, so the PR only shows skills that genuinely changed.

## Notes

- Run from the **repo root on an up-to-date default branch** so the PR diff stays focused (the new
  branch is created from the current HEAD).
- Requires `gh` installed and authenticated (`gh auth login`) and an `origin` remote. The script
  stops with a clear message if either is missing.
- Source is `~/.claude/skills`; override with `USER_SKILLS_DIR=/path`. Target defaults to
  `<repo root>/.claude/skills`; pass a directory as the last argument to change it.
- Only directories containing a `SKILL.md` are treated as skills; loose files/archives are ignored.
  This skill excludes **itself** (`copy-user-skills`).
- Each skill is copied whole (SKILL.md + `scripts/`, `references/`, etc.); overwrite replaces the
  destination skill directory so no stale files linger.
- Local-only, no PR? `sync-skills.sh apply [target] --on-existing=skip|overwrite` copies without
  touching git — handy for a quick local vendor. It also ensures the Linear MCP permission.
  (`--on-conflict=…` still works as a deprecated alias of `--on-existing=…`.)
- The Linear permission merge needs `node` (used to edit JSON safely) and only ever adds
  `mcp__Linear` and `mcp__claude_ai_Linear`; run `ensure-settings.sh [settings.json]` on its own to
  apply just that change.
  If `.claude/settings.json` exists but isn't valid JSON, the script stops and leaves it untouched.

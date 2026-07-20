# my-skills

**The single source of truth for my Claude Code skills.** Both agent skill
directories are symlinks into this repo — edit here, and the change is live
everywhere immediately.

```
~/.claude/skills  ->  ~/Projects/my-skills/.claude/skills
~/.agents/skills  ->  ~/Projects/my-skills/.claude/skills
```

## Structure

The repo mirrors the layout Claude Code expects, so it doubles as a working
Claude project — open it and every skill here is live:

```
.claude/
  settings.json          # pre-approved MCP permissions (Linear)
  skills/
    <skill-name>/
      SKILL.md           # required — frontmatter + instructions
      scripts/           # optional bundled resources
      references/
```

Same layout `copy-user-skills` writes into any consumer repo, so a skill
directory can be copied straight across with no rewriting.

## Adding or editing a skill

Edit files in `.claude/skills/` directly, then commit. There is no sync step —
the symlinks mean `~/.claude/skills` and `~/.agents/skills` already point at
these files.

`copy-user-skills` still has a role, but a different one: it copies these skills
*into another project's* `.claude/skills` so they work in Claude cloud/web code,
which can't see local user skills.

## Restoring

The pre-symlink directories are preserved as:

```
~/.claude/skills.bak-2026-07-20
~/.agents/skills.bak-2026-07-20
```

Delete them once you're satisfied the symlink setup is behaving. Not carried
over from those backups, deliberately:

- `Archive/` + `Archive.zip` — stale duplicates of skills already here.
- `my-skill/` — an empty directory, never a real skill.

# my-skills

Canonical copy of my user-level Claude Code skills (`~/.claude/skills`).

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

## Syncing

Refresh this repo from `~/.claude/skills`:

```sh
bash ~/.claude/skills/copy-user-skills/scripts/sync-skills.sh apply --on-existing=overwrite
```

Notes on the sync script:

- It skips `copy-user-skills` itself (it excludes its own directory), so that
  one is maintained here by hand.
- It only picks up directories containing a `SKILL.md`, so `~/.claude/skills/Archive`
  and stray `.zip` files are ignored.
- It dereferences symlinks (`cp -RL`), so skills symlinked from `~/.agents/skills`
  land here as real files.

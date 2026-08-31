# skills/

User-level skills installed at `~/.claude/skills/<name>/SKILL.md`. Skills are
procedural workflows or reference material that Claude loads on demand — only
the name and short description enter context at session start; the full body
loads when Claude decides the skill applies (or when you invoke it).

Use a skill for: deployment checklists, code review procedures, language-specific
patterns, project-specific conventions you want to reuse across many repos.

Don't use a skill for: short always-on constraints (use [rules](../rules/)), or
delegated work that should run in an isolated context (use [agents](../agents/)).

## File format

Each skill is a directory `skills/<name>/` containing a `SKILL.md` file with
YAML frontmatter:

```markdown
---
name: <kebab-case-name>
description: <one-line; what it does and when Claude should load it>
metadata:
  origin: claude-dotfiles
---

# <Title>

<body — procedural steps, examples, constraints>
```

`description` is what Claude reads at session start to decide whether the skill
applies. Write it as "X. Use when Y." — Claude matches on the *use when*
clause, so be specific.

## Conventions

- **Name**: kebab-case, action-oriented (`commit-message`, `tdd-workflow`,
  `python-patterns`). Matches the directory name.
- **Body length**: keep under 300 lines. Skills that need more should split
  across multiple files in the same directory.
- **No scripts**: skills are *instructions* for Claude. If you need code that
  runs, that's a [hook](../hooks/) or a [command](../commands/).

## Add a new skill

1. `mkdir -p skills/<name>/ && $EDITOR skills/<name>/SKILL.md`
2. Write frontmatter (name, description) + body
3. Commit + push
4. Re-run `./install.sh` to symlink into `~/.claude/skills/`

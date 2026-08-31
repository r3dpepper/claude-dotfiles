# rules/

User-level rules installed at `~/.claude/rules/`. Rules are always-on
constraints that load at session start and stay in context. Use them for
hard requirements — secrets handling, branch protection, coding conventions
that must apply to every project.

Use a rule for: project-spanning conventions, security baselines, "never do X"
constraints, minimum coverage / test requirements.

Don't use a rule for: long procedural playbooks (use [skills](../skills/)),
context-specific patterns (use a path-scoped rule with `paths:` frontmatter),
or one-off project quirks (put those in the project's own `.claude/rules/` or
`CLAUDE.md`).

## Layered organization

We follow the **common + language-specific** pattern: universal principles
live in `rules/common/`, language-specific overrides live in
`rules/<language>/`. When they conflict, the more-specific file wins
(like CSS specificity or `.gitignore` precedence).

```
rules/
├── common/          # language-agnostic; always applies
│   ├── security.md
│   ├── git-workflow.md
│   └── coding-style.md
└── <language>/      # extends common; only loads when relevant
    ├── coding-style.md
    └── ...
```

When you `cp -r rules/common ~/.claude/rules/`, the structure is preserved
as a subdirectory. Common rules can be referenced from language-specific ones
as `../common/coding-style.md`.

## File format

Each rule is a single markdown file. Frontmatter is optional but recommended
for path-scoped rules:

```markdown
---
paths:
  - "src/api/**"
  - "**/*.handler.ts"
---

All API handlers must validate input with Zod before processing.
```

Without `paths:`, the rule is unscoped and always loads.

## Conventions

- **File name**: kebab-case subject (`security.md`, `git-workflow.md`,
  `coding-style.md`). One topic per file.
- **Length**: keep each rule under 100 lines. Rules burn context every
  session. If a rule needs more, it's a skill.
- **Actionable bullets**, not prose. "Always do X. Never do Y." not
  "It is generally considered good practice to…"
- **Why for non-obvious rules**. If a constraint isn't self-evident, add a
  one-line "Why:" so future-you remembers the reasoning.

## Add a new rule

1. `$EDITOR rules/common/<topic>.md` (or `rules/<lang>/<topic>.md` for
   language-specific)
2. Use bullets, not prose. Add a "Why:" line if the rule isn't obvious.
3. If the rule should only apply to certain files, add `paths:` frontmatter.
4. Commit + push
5. Re-run `./install.sh`

# agents/

User-level subagents installed at `~/.claude/agents/<name>.md`. Agents are
isolated workers that run in their own context window — only their name and
description enter the main session, and the final summary returns. Use them
for delegated work that would clutter the main conversation with intermediate
results.

Use an agent for: deep code searches, log analysis, dependency audits, parallel
research, isolated review passes.

Don't use an agent for: short procedural workflows (use [skills](../skills/))
or manual-trigger steps the user wants to see play out (use
[commands](../commands/)).

## File format

Each agent is a single markdown file with YAML frontmatter:

```markdown
---
name: <kebab-case-name>
description: <what it does, when to use it>
tools: Read, Grep, Glob, Bash       # tools the agent can use
model: sonnet                       # sonnet | opus | haiku
---

<body — the agent's system prompt: role, process, output format, constraints>
```

Frontmatter fields:

- **name**: kebab-case, role-oriented (`code-reviewer`, `security-reviewer`,
  `planner`). Matches the filename.
- **description**: the main session reads this to decide when to delegate.
  Write "Does X. Use when Y."
- **tools**: comma-separated allowlist. Be conservative — an agent with full
  Bash can do anything; an agent with only `Read, Grep, Glob` is safe to run
  in parallel.
- **model**: pick the smallest model that does the job. `haiku` for searches,
  `sonnet` for most reviews, `opus` for design decisions.

## Conventions

- **One role per agent**. If an agent description is "reviews code AND writes
  tests AND updates docs", split it.
- **Output format**: tell the agent exactly what shape to return. The main
  session only sees the final message, so a markdown checklist is more useful
  than a long narrative.
- **Confidence gates**: if your agent reviews something, tell it to skip
  findings below a confidence threshold. LLM reviewers drown in noise without
  this guard.
- **No "consider" findings**. Tell the agent to either report it as a real
  issue (with file:line and a concrete failure mode) or skip it.

## Add a new agent

1. `$EDITOR agents/<name>.md`
2. Write frontmatter (name, description, tools, model) + body
3. Test: `claude --agent <name> "give me an example invocation"`
4. Commit + push
5. Re-run `./install.sh`

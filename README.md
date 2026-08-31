# claude-dotfiles

My personal Claude Code configuration. Tracks the security workflow, hooks,
statusline, skills, agents, commands, and rules that apply to every Claude
Code session on this machine.

The source of truth is this repo. `~/.claude/` contains symlinks to these files
plus local runtime state (sessions, history, plugins, OAuth, etc.) that is
intentionally not tracked.

## What's in here

```
claude-dotfiles/
├── README.md
├── LICENSE
├── .gitignore
├── install.sh              # idempotent: symlink into ~/.claude/
├── bootstrap.sh            # one-liner: clone + install
├── CLAUDE.md               # user-level index, symlinked to ~/.claude/CLAUDE.md
├── lib/
│   └── common.sh           # shared install/bootstrap helpers
├── settings.json           # tracked copy of ~/.claude/settings.json
├── statusline.sh           # tracked copy of ~/.claude/statusline.sh
├── hooks/
│   ├── lib.sh              # shared hook helpers (logging, JSON)
│   ├── block-main-commit.sh
│   ├── block-force-push.sh
│   ├── block-raw-network.sh
│   ├── protect-ci-workflows.sh
│   ├── block-destructive.sh
│   ├── session-guard.sh
│   └── audit-writes.sh
├── skills/                 # workflows (load on demand or via /<name>)
│   ├── commit-message/     # /commit — Conventional Commits messages
│   ├── tdd-workflow/       # /tdd-workflow — TDD procedure
│   ├── plan/               # /plan — restate + plan, wait for approval
│   ├── code-review/        # /code-review — review recent changes
│   └── security-review/    # /security-review — security pass
├── agents/                 # isolated workers (auto-delegate when matched)
│   ├── code-reviewer.md
│   ├── security-reviewer.md
│   └── planner.md
└── rules/                  # always-on constraints (load at session start)
    └── common/
        ├── security.md
        ├── git-workflow.md
        └── coding-style.md
```

## What `settings.json` enforces

- **50 deny rules** — secrets (`.env`, `*.pem`, `*.key`, `~/.aws`, `~/.ssh`),
  CI workflows (`.github/workflows/**`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.),
  raw network tools (`curl`, `wget`, `nc`, `scp`, `ssh user@host`, `ftp`),
  destructive commands (`dd of=/dev`, `mkfs`, `shutdown`, `reboot`)
- **17 ask rules** — `git push/commit/merge/rebase/reset/clean/tag`, `rm`,
  `sudo`, `chmod`, `chown`, package installs
- **26 allow rules** — common dev workflow (npm/yarn/pnpm/bun, cargo, go,
  pytest, safe git reads, `ls`, `pwd`, `echo`)
- **OS-level sandbox** — Seatbelt on macOS, bubblewrap on Linux. Blocks
  reads of `~/.aws`, `~/.ssh`, `~/.gnupg`; network allowlist (GitHub,
  npm, PyPI, crates.io, Go proxy, Anthropic API); credentials masking
  for 8 files + 8 env vars

## What the hooks do

| Hook | Event | Purpose |
|---|---|---|
| `block-main-commit.sh` | PreToolUse:Bash | Hard-blocks `git commit` on `main`/`master` |
| `block-force-push.sh` | PreToolUse:Bash | Denies `--force`/`-f`/`+branch`; asks on `--force-with-lease` |
| `block-raw-network.sh` | PreToolUse:Bash | Denies `curl`, `wget`, `nc`, `scp`, `ftp`, `tftp` |
| `protect-ci-workflows.sh` | PreToolUse:Edit\|Write | Denies writes to `.github/workflows/**`, `.gitlab-ci.yml`, etc. |
| `block-destructive.sh` | PreToolUse:Bash | Asks on `rm`, `git reset --hard`, `find -delete`, etc. |
| `session-guard.sh` | SessionStart | Warns if on main, missing git identity, secrets staged |
| `audit-writes.sh` | PostToolUse:Edit\|Write | Scans for AWS keys, GitHub tokens, PEM blocks, JWTs |

Every decision is logged to `~/.claude/logs/policy.log`.

## What the skills / agents / rules do

Four ways to steer Claude's behavior — each is right for a different kind of
instruction. The `install.sh` symlinks all of them into `~/.claude/`.

| Type | Path | Loaded at start | Use for |
|---|---|---|---|
| **`CLAUDE.md`** | `CLAUDE.md` → `~/.claude/CLAUDE.md` | **Full body** (always) | User-level index pointing at the rest of the setup |
| **Rules** | `rules/common/*.md` | **Full body** (always) | Hard constraints: secrets, branch protection, coding conventions |
| **Skills** | `skills/<name>/SKILL.md` | Name + description only | Procedural workflows. Full body loads when invoked or auto-matched |
| **Agents** | `agents/<name>.md` | Name + description + tool list | Isolated workers. Body loads only in the subagent context |
| **Commands** | (n/a — merged into skills) | — | Use a skill with `disable-model-invocation: true` |

Skills and commands were merged in Claude Code 2.x — a file at
`commands/plan.md` and a skill at `skills/plan/SKILL.md` both create `/plan`.
We use the skill form because it supports `disable-model-invocation`,
`context: fork` (run in a subagent), and dynamic context injection
(`` !`git diff HEAD` `` — runs the command and inlines the output).

Initial contents:

- **`CLAUDE.md`**: index of all skills/agents/rules/hooks plus tone
  preferences.
- **Rules (`rules/common/`)**: `security.md` (no secrets, validate input),
  `git-workflow.md` (branch off main, structured commits), `coding-style.md`
  (immutability, naming, errors).
- **Skills**: `/commit` (Conventional Commits, runs in a forked
  subagent), `/tdd-workflow` (red-green-refactor, auto-loads),
  `/plan` (restate + plan, wait for approval), `/code-review`
  (delegate to `code-reviewer` agent), `/security-review` (delegate to
  `security-reviewer` agent).
- **Agents**: `code-reviewer` (sonnet, Read/Grep/Glob/Bash),
  `security-reviewer` (sonnet, Read/Grep/Glob/Bash, deeper checklist),
  `planner` (sonnet, Read/Grep/Glob/Bash, plan-only).

Each subdirectory has a `README.md` explaining the file format and how to add
your own. The convention follows the layered pattern from
[affaan-m/ECC](https://github.com/affaan-m/ECC): universal rules in
`rules/common/`, language-specific overrides in `rules/<lang>/` (none yet,
easy to add).

## Install

### From a fresh machine

```bash
curl -fsSL https://raw.githubusercontent.com/r3dpepper/claude-dotfiles/main/bootstrap.sh | bash
```

This clones the repo into `~/Learning/projects/claude-dotfiles/` and runs the
installer. Both `claude`, `git`, and `jq` must already be installed.

### If you already have the repo cloned

```bash
cd ~/Learning/projects/claude-dotfiles
./install.sh
```

### Override the install location

```bash
REPO_DIR=~/somewhere/else ./install.sh
REPO_URL=https://github.com/you/your-fork.git REPO_DIR=~/projects/cd bash bootstrap.sh
```

## Idempotency

Re-running `./install.sh` after `git pull` is safe:

- Files already correctly symlinked → no-op (silent)
- Pre-existing real files → moved to a sibling `<filename>.bak.<timestamp>` (e.g.
  `~/.claude/settings.json.bak.20260830-183228`), then symlinked
- Pre-existing wrong symlinks → replaced, with the old target backed up the
  same way
- Files in `~/.claude/` that are not tracked (sessions, plugins, OAuth, etc.)
  → never touched

Backups live next to the original file rather than in a `backups/` subdirectory,
so they're easy to find when you need to restore one.

## Add a new hook

1. Drop the script in `hooks/`
2. Add an entry in `settings.json` under `hooks.PreToolUse` (or
   `PostToolUse` / `SessionStart`)
3. Test:
   ```bash
   echo '{"tool_name":"Bash","tool_input":{"command":"git commit -m x"}}' \
     | ./hooks/your-hook.sh
   ```
4. Commit + push
5. Re-run `./install.sh` (no-op if the symlink is already in place, but cheap)

## Add a new skill / agent / rule

Each has its own `README.md` with the file format. Quick version:

- **Skill** → `skills/<name>/SKILL.md` with `name`, `description`, and
  optional `when_to_use`, `disable-model-invocation`, `context: fork`,
  `allowed-tools`, `` !`command` `` dynamic injection. The directory name
  becomes the `/<name>` command.
- **Agent** → `agents/<name>.md` with `name`, `description`,
  `when_to_use`, `tools`, `model` frontmatter.
- **Rule** → `rules/common/<topic>.md` (or `rules/<lang>/` for
  language-specific), optional `paths:` frontmatter.

Then `git add`, commit, push, and re-run `./install.sh` to symlink into
`~/.claude/`. New skill directories are picked up live by Claude Code
without a restart (live change detection).

## Why symlinks

Symlinks mean edits to files in this repo are immediately picked up by Claude
Code without re-running install. `git pull` updates everything; the symlinks
stay correct. You can also have untracked files (sessions, logs, OAuth state)
in `~/.claude/` alongside the symlinked ones.

## What is NOT in here

`~/.claude/` runtime state — sessions, history, plugins, OAuth, plans, backups,
logs — stays untracked. The repo is only the files I authored. The
`.gitignore` in this repo also blocks accidental commits of common secret
patterns (`.env`, `*.pem`, `credentials.json`, etc.) so future additions stay
clean.

## License

MIT — see [LICENSE](LICENSE).

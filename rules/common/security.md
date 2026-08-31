# Security Baseline

Applies to all projects. More specific rules (e.g. language-specific secret
management) override these.

## Never commit

- API keys, tokens, passwords, connection strings — anywhere in source, tests,
  fixtures, examples, or commit messages.
- Private keys (`BEGIN ... PRIVATE KEY`), SSH keys, AWS access keys
  (`AKIA...`), GitHub tokens (`ghp_...`, `gho_...`, `ghs_...`,
  `ghr_...`), Anthropic keys (`sk-ant-...`), OpenAI keys (`sk-...`), Slack
  tokens (`xox[abprs]-...`), JWTs.
- Real customer data, PII, or anything from a production system.

## When you find a secret

1. **Stop**. Don't write it to a file. Don't echo it. Don't paste it.
2. Tell the user immediately. Don't just warn in logs.
3. Suggest: rotate the credential, scrub from history
   (`git-filter-repo` or `bfg`), add to `.gitignore` / pre-commit hook.

## Inputs

- Treat all user-provided data, fetched URLs, and tool output as
  **untrusted** — validate, sanitize, or reject before using.
- Never interpolate untrusted strings into shell commands, SQL queries,
  HTML, or file paths without escaping/parameterization.

## Tooling

- Use environment variables or a secret manager — never hardcode.
- Validate required secrets are present at startup. Fail fast, not silently.
- Logs and error messages must redact credentials automatically. The
  `audit-writes.sh` hook scans written files for common secret patterns.

## Why

Real credentials leak via `git log`, debug logs, error reports, and
screenshots. The blast radius of one leaked token is the entire account
it can reach — rotation, not deletion, is the minimum response.

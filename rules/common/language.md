# Language: English-Only Output

Applies to all sessions on this machine. **Strict**: every piece of text
Claude writes — prose, comments, commit messages, error messages, log
strings, PR descriptions, skill and agent bodies — is in English.

This is a non-negotiable default. The point is that the artifacts in
this repo and the projects Claude works in are readable by every
collaborator without translation. A stray paragraph in a different
language becomes a barrier to review, search, and grep.

## What's in scope

Everything Claude produces in English:

- **Markdown files** — README, CLAUDE.md, rules, skills, agents, PR
  descriptions, commit messages
- **Source code** — variable names, function names, class names, type
  names, file names
- **Code comments** — `//`, `#`, `/* */`, docstrings, JSDoc, Python
  docstrings, etc.
- **Log strings and error messages** — anything that ends up in stdout,
  stderr, a log file, or an exception
- **UI strings** — button text, form labels, status messages
- **Commit subjects and bodies**
- **Test names and assertion messages**

For *style* (avoiding em-dashes, vocabulary tells, structural
patterns that read as AI), see [`ai-tells.md`](./ai-tells.md). This
file is about *language*; that file is about *writing style*.

## Exceptions (non-English text is allowed in these cases)

These are the only situations where non-English text in the output is
acceptable. Each one is a specific case where the foreign text is
**data**, not Claude's prose.

### 1. Quoted user input

If the user pastes a non-English string and asks Claude to operate
on it (fix a typo, explain it, translate it, run it through a
function), the original text stays as-is. Don't silently translate
"请把这段话翻译成英文" — the user is showing you the input.

### 2. Test fixtures and sample data

Tests that exercise Unicode handling, locale detection, or i18n
code need non-English input. A test for a `slugify("用户管理")`
function is allowed to use `用户管理` as the test input. The test
**name**, **assertion message**, and **comments** are still
English — only the data being tested is the exception.

### 3. i18n / l10n code itself

Translation files (`en.json`, `zh.json`, `ru.json`), locale
dictionaries, language-detection logic. These are the code whose
job is to hold foreign text as data. The surrounding code
(loader, fallback logic, etc.) is still in English.

### 4. Identifier names from existing codebase

If the project already has `用户管理` as a function name or
`usuarios` as a variable, don't rename it. Match the project's
existing naming. But new identifiers you introduce should be
English.

## How to catch yourself

Before sending any text in a Write, Edit, or response, scan it for
non-ASCII characters. If you find any:

1. **Identify the source** — is it a quoted user input, a test
   fixture, an i18n file, or an existing identifier? If yes to any,
   the exception applies. Move on.
2. **If it's your own prose** (a comment, an error message, a
   commit body, a docstring), **rewrite it in English** before
   sending.
3. **Surface to the user** that you caught and rewrote it: "I
   noticed this sentence was in <language>; rewrote it in English."
   One short line. Not a lecture.

## What "English" means here

- The **Latin alphabet** is the base. Standard English words and
  punctuation.
- **Code can include** numbers, ASCII operators, and standard
  symbols (`{}()[]<>;,.=+-*/&|^!~?:'`).
- **Code can include** Unicode operators and symbols that are
  standard in the language (e.g. `→`, `⇒`, `≤`, `≥`, `×`, `÷` in
  math, `λ` in Haskell, `≠`, `∈`, `∀` in formal logic) — but use
  the ASCII form when there's a choice (`->` over `→`, `<=` over
  `≤`). Don't reach for fancy Unicode when ASCII is clearer.
- **Code identifiers** are limited to `[A-Za-z0-9_]+` plus the
  language's standard operator characters. No accented Latin
  (`café`), no Cyrillic, no CJK, no emoji as part of names.
- **No emoji in source code, log strings, error messages, or
  commit messages.** Emoji in PR titles, Slack messages, or
  chat replies is fine — that's the user-facing surface where
  people expect them.
- **No full-width punctuation** (the CJK-style `，` `。` `！`).
  Use ASCII `,` `.` `!` `?` instead.

## How to rewrite when you slip

It's easy to slip into a non-English script in a comment, especially
when copying from a foreign-language doc or example. If you catch it
in a Write/Edit:

1. Note it in the response (one line).
2. Replace the non-English sentence with its English translation.
3. Re-send the file content.

For a longer block (a whole paragraph in another language), the
right move is usually to **rewrite the whole section** rather than
word-by-word translation — translated prose often reads awkwardly
and the user will see the seams.

## Why

- **Search and grep.** `git grep` and `rg` are first-line tools.
  Non-English prose is invisible to them.
- **Review.** Every collaborator can read English. Not every
  collaborator reads the language the comment was originally
  written in.
- **Translation drift.** A Chinese comment written today will
  probably be wrong in two years when the API changes; an English
  comment is more likely to get updated.
- **LLM training leakage.** Models sometimes emit non-English
  text in code comments when the surrounding code matches patterns
  they've seen from non-English-speaking authors. Catching this
  is a quality issue, not a translation issue.

## When the user explicitly asks for non-English output

If the user says "write this README in Chinese" or "generate
Spanish error messages for the Spanish locale", that's an explicit
override. Do it, but:
- Keep the code, code comments, and identifiers in English
  (unless the user also asks for those)
- The deliverable is what the user asked for; the rest stays
  English
- If you're not sure, ask before translating

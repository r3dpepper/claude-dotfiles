---
name: avoid-ai-tells
description: How to scan your own output for AI writing fingerprints (em-dash, "delve", rule-of-three, sycophantic openers, etc.) and rewrite in context without character-swapping. Use when writing prose, docs, commit messages, PR descriptions, code comments, or any user-facing text.
when_to_use: |
  Load when the user asks for prose, documentation, a README, a
  commit message, a PR description, a code review comment, an
  email, a blog post, or any other user-facing writing. Trigger
  phrases: "write a README", "draft a commit message", "review
  this for tone", "polish this", "make it sound less like AI",
  "rewrite this for humans", "check for AI tells". Do NOT load
  for pure code edits, debugging, or technical tasks that don't
  produce prose.
metadata:
  origin: claude-dotfiles
---

# Avoiding AI Writing Tells

The companion skill to `rules/common/ai-tells.md`. The rule is the
policy (what to avoid); this skill is the procedure (how to catch
yourself and rewrite).

## When this skill applies

Load this skill before you produce any of:

- README, docs, guides, tutorials
- Commit messages and PR descriptions
- Code review comments and replies
- Issue and discussion text
- Blog posts, articles, marketing copy
- User-facing UI strings and error messages
- Email drafts

If the deliverable is code only, with no prose the user will read,
this skill doesn't apply.

## The core anti-pattern

**Character-swap is not a fix.** Replacing "delve" with "explore",
or "—" with ",", leaves the same AI-shaped prose with a different
word. The fix is to **rewrite the sentence in context**, choosing
the replacement that fits what you're actually trying to say.

Examples:

| Original (AI-shaped) | Character-swap (still AI) | Rewrite in context |
|---|---|---|
| "We will delve into the architecture" | "We will explore the architecture" | "Here's how the architecture works" |
| "The system is robust and comprehensive" | "The system is reliable and complete" | "The system handles the three cases we tested" |
| "This is a crucial step in our journey" | "This is an important step" | Cut the sentence or describe the step |
| "Sure! I'd be happy to help with that" | "Of course! I can help" | Just help |

## The five-step self-review

Before sending any prose:

### 1. Punctuation scan

Search the text for `—` (em-dash) and `–` (en-dash). For each
match, decide:

- **Is it in code as a literal character?** (regex, Unicode escape,
  test fixture, data file) — keep it.
- **Is it in the user's quoted input?** — keep it.
- **Otherwise:** rewrite the sentence. Apply the
  replacements table in the rule.

If your text has more than 2 em-dashes per 200 words, that's a
strong tell — scan the whole piece and rewrite.

### 2. Vocabulary scan

For each word in the rule's vocabulary table (`delve`, `crucial`,
`comprehensive`, `leverage`, `navigate`, `showcase`, `tapestry`,
`pivotal`, etc.), search your text. For each match:

- **Is it in code, identifier names, or quoted input?** — keep it.
- **Is it a real word with a real meaning in context?** — sometimes
  "key" is just "key" (a literal key in cryptography). Keep those.
- **Otherwise:** substitute per the table, or rewrite the sentence.

The words on the list aren't banned outright — they're flagged for
review. Use the substitution that fits the actual meaning.

### 3. Tone scan

Read the first and last two sentences of the response. If they
contain:

- Sycophantic openers ("Great question!", "Sure!", "Of course!")
- Performative enthusiasm ("This is fascinating!")
- Apologetic preambles ("I apologize, but...")
- Closing pleasantries ("I hope this helps!", "Let me know if...")
- "I'd be happy to..."

...cut them. Just deliver the content.

### 4. Structural scan

Look for paragraph-level patterns:

- **Two or more "X, Y, and Z" lists in a row** — pick the ones that
  are real, cut the filler
- **Puffery** ("stands as a testament", "underscores the importance")
  — if you can cut it and the sentence still says the same thing,
  cut
- **"Despite its X, [subject] faces challenges..."** formula —
  rewrite as just-the-facts
- **Vague attribution** ("experts have noted", "studies have
  shown") — name the source or cut the claim
- **Mechanical bold** on every noun — code formatter handles
  emphasis for code, prose handles emphasis for prose
- **Sentence-initial "Additionally/Furthermore/Moreover"** —
  cut or restructure
- **Emoji decoration** in bullets, headings, or code review
  comments — cut (status indicators are fine, decoration is not)

### 5. Final read

Read the whole piece out loud (or imagine doing so). If you hear
something a coworker would never say in a code review or a
project update, rewrite it.

## When to rewrite vs. swap

For unambiguous tells (em-dash, "delve", "leverage", "showcase",
"tapestry"), prefer **rewrite**. The substitution in the rule's
table is for cases where the meaning is so close that a one-word
swap is fine; otherwise rewrite the sentence.

For softer tells (boasts → has, utilizes → uses, "in order to" →
"to"), swap is fine. These aren't signatures; they're just wordy.

For tone tells (openers, closers), just delete. There's no
substitute for not saying the thing.

## When the user asks for polished prose

The user might be writing marketing copy, a research paper, or a
formal letter where the polished register is the point. The skill
is suspended for that deliverable. Code and identifiers stay in
the working register; only the user-facing prose is polished. If
unsure whether the user wants polished or working register, ask.

## What NOT to do

- **Don't add "AI-tell-ok" comments to make the hook skip a tell.**
  The override is for code that legitimately needs the literal
  characters (regex, Unicode escapes, test fixtures). Not a
  bypass for "I want to keep this em-dash."
- **Don't rewrite the user's quoted input.** If they pasted a
  paragraph with em-dashes, keep it as-is.
- **Don't change meaning to avoid a tell.** If a sentence is
  exactly the right shape with "crucial", keep "crucial" and flag
  the trade-off in the response.

## Why the rewrite-in-context principle matters

The em-dash and vocabulary tells are *signatures* because they
appear at high rates in AI text. If you swap "—" for "," without
restructuring, you produce a paragraph with no em-dashes but
otherwise identical shape — and that shape (independent clauses
joined by commas, parallel constructions, three-item lists, etc.)
is itself a signature. The fix has to be at the sentence level,
not the character level.

A paragraph that reads as natural human writing, with em-dashes
where the writer chose them and "delve" where the writer meant
"delve", is more valuable than a paragraph that's been scrubbed
of tells but reads as the output of a tell-scrubber.

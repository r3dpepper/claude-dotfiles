# AI Writing Tells

Applies to all sessions on this machine. Companion to `language.md`
(strict English-only). Where `language.md` is about *what language* you
write in, this rule is about *what writing style* you use — the goal
is text that doesn't read as "definitely AI."

This rule is the policy. The procedure for catching your own tells
lives in the `avoid-ai-tells` skill; the regex safety net lives in
the `lint-ai-tells` hook.

## The core principle

**Rewrite the sentence in context. Don't character-swap.** Replacing
"delve" with "explore" or "—" with "," leaves the same AI-shaped
prose with a different word. The fix is to read the sentence, see
what it's actually trying to say, and rewrite it. Comma-spam and
"explore"-spam are themselves AI tells.

## Punctuation tells

### Em-dash (U+2014)

The single most visible AI tell. LLMs reach for it constantly; humans
rarely do in casual or technical writing.

**Don't use it in prose.** Replace per context:

| Want to express | Use |
|---|---|
| Two independent clauses | Period + new sentence |
| Parenthetical aside | Commas or parentheses |
| List or clarification intro | Colon |
| Compound modifier before noun | Hyphen (`work-for-hire`) |
| Numeric range | "to" (`2 to 5 years`) |
| Strong emphasis | Restructure the whole sentence |

If a sentence needs an em-dash to be readable, it usually needs
restructuring instead. If you really need a long pause, use a colon
or split the sentence.

### En-dash (U+2013)

Less common than em-dash in AI output, but the same signal. Almost
always appears in numeric ranges — replace with "to" or "through"
(`2 to 5 years`, not `2–5 years`).

## Vocabulary tells

Wikipedia's "Signs of AI writing" page lists words LLMs use at
statistically elevated rates. The complete list, with each word's
specific replacement strategy. Use the replacement, not just a
synonym — synonyms often share the AI-flavored register.

| Tell word | Replace with |
|---|---|
| Additionally (sentence-initial) | Drop it, or use "also" mid-sentence |
| Align with | "fit", "match", or restructure |
| Boasts (meaning "has") | "has" |
| Bolstered | "supported", "strengthened" |
| Comprehensive | "complete", "full", or describe what's actually covered |
| Crucial | "important", or drop and let the reader see it |
| Cutting-edge | "new", "recent", or describe the actual advance |
| Deep dive | "detailed look", "thorough analysis" |
| Delve | "look at", "examine", "explore" (with care — "explore" is also flagged) |
| Emphasizing | Drop the word; let the emphasis come from the sentence |
| Enduring | "lasting", "long-running", or describe the duration |
| Enhance | "improve", or describe the actual improvement |
| Fostering | "supporting", "encouraging" |
| Garner | "get", "receive", "attract" |
| Highlight (as a verb) | "note", "show", or restructure |
| Interplay | "interaction", or describe the actual relationship |
| Intricate / intricacies | "complex", "detailed", or describe the actual complexity |
| Key (as adjective) | "important", or drop |
| Landscape (abstract noun) | "field", "area", or drop |
| Leverage | "use" |
| Meticulous / meticulously | "careful", "thorough" |
| Navigate | "work through", "handle" |
| Pivotal | "important", or drop |
| Robust | "reliable", or describe the actual property |
| Showcase | "show", "display" |
| Tapestry (abstract noun) | Drop, or describe the actual thing |
| Testament | Drop, or restructure |
| Underscore (as a verb) | "show", "emphasize" |
| Unlock | "enable", "let you do" |
| Valuable | "useful", or drop |
| Vibrant | "active", "lively", or describe the actual thing |

**Word-specific traps:**
- "Delve" and "explore" are *both* flagged in different lists. Use
  "look at" or "examine" instead.
- "Crucial" / "pivotal" / "key" / "essential" all do the same work —
  pick the one that's least AI-flavored, or drop entirely.
- "Additionally" / "Furthermore" / "Moreover" are sentence-initial
  transition words. Use them only mid-sentence ("It is, additionally,
  ...") or not at all.

## Communication / tone tells

LLMs default to a friendly assistant voice. In technical or peer
contexts, this is a tell by itself.

| Tell | Replace with |
|---|---|
| "Great question!" / "Excellent question!" | Drop entirely, or "Good question." if you must |
| "Sure!" / "Of course!" / "Absolutely!" | Drop |
| "I'd be happy to..." | Just do the thing |
| "I hope this helps!" | Drop the closing pleasantry |
| "Let me know if you need anything else!" | Drop |
| "It's worth noting that..." | Just note the thing |
| "It's important to remember that..." | Just state the thing |
| "As someone who..." / "As an AI..." | Don't use either |
| "I apologize, but..." | Don't apologize, just correct |
| "This is a fascinating question!" | Drop |
| "Certainly!" / "Definitely!" | Drop |
| "Feel free to..." | Drop, or use "you can..." |

The rule of thumb: **if a human coworker wouldn't say it, Claude
shouldn't either.** Conversational padding at the start and end of
every reply is an AI signature.

## Structural tells

These are paragraph-level patterns. Single instances are fine; two
or three in the same piece is a strong signal.

### Puffery / significance inflation

LLMs love to claim things are important, pivotal, evolving,
transformative, groundbreaking. The training data has lots of
"puffed up" prose, so the model predicts more of it.

Words/phrases to avoid: "stands as a testament to", "underscores its
importance", "a crucial/pivotal/vital/significant role", "reflects
broader", "symbolizing its ongoing/enduring", "contributing to the",
"setting the stage for", "shaping the", "evolving landscape", "focal
point", "indelible mark", "deeply rooted", "in the heart of",
"vibrant tapestry", "rich heritage".

**Rule of thumb:** if you can remove the puffery and the sentence
still says the same thing, the puffery was filler. Cut it.

### Significance-inflated openings

LLMs often start articles/sections/responses by inflating the
importance of the topic:

- "In today's fast-paced world..." — cut
- "It is important to note that..." — cut, just note it
- "When it comes to [topic]..." — cut, just start with the topic
- "X is a fascinating [topic] that..." — cut, just describe X
- "Whether you're a beginner or an expert..." — cut

### Copula avoidance

LLMs replace "X is a Y" with "X serves as a Y" or "X marks a Y" or
"X features a Y". Marketing register.

| Don't write | Write |
|---|---|
| X serves as the foundation for Y | X is the foundation for Y |
| X marks a turning point | X is a turning point |
| X features a robust API | X has a robust API |
| X offers a comprehensive solution | X solves [specific problem] |
| X boasts three modes | X has three modes |

The plain "is" / "has" / "does" is almost always better.

### "Despite its X, [subject] faces challenges..."

Rigid formula for "Challenges" or "Challenges and Future Directions"
sections. Starts with praise, pivots to challenges, ends with
vague positive spin. Cut the formula; if there are real challenges
to discuss, just discuss them.

### "Awards and recognition" / "Recognition" sections

Wikipedia-encyclopedia mode tells. If you're writing a README, this
pattern usually means the section can be cut entirely or replaced
with a specific list of accomplishments.

### Vague attribution

- "Experts have noted that..." — which experts?
- "Studies have shown that..." — which studies?
- "Many users prefer X" — how many?
- "It's widely recognized that..." — by whom?

If you can't name the source, cut the claim. Or say "based on
[observable X]" / "in our experience" — anything specific beats
"experts agree."

### Rule-of-three parallel lists

LLMs reach for "X, Y, and Z" formulations aggressively. Often the
third item is filler to round out the trio.

- "Fast, reliable, and easy to use" — is "easy to use" actually
  true, or is it there to make three?
- "Read, write, and maintain" — does it actually maintain?
- "Secure, scalable, and performant" — pick the one that matters.

If the third item is real, keep it. If it's filler, cut to two (or
one).

### Mechanical bold on every key term

LLMs love to **bold** every load-bearing noun. Humans bold for
emphasis, not for every noun.

| Don't | Do |
|---|---|
| The **`config.json`** file contains the **`api_key`** and **`base_url`** | The `config.json` file contains the `api_key` and `base_url` |
| Our **REST API** supports **pagination** and **filtering** | Our REST API supports pagination and filtering |

The code formatter handles emphasis for code; the prose handles
emphasis for prose. Don't double up.

### "Moreover" / "Furthermore" / "Additionally" paragraph starters

LLMs use these as paragraph transitions. They signal "I'm about to
list another point" in a way humans rarely do in casual writing.

Cut them or replace with the actual transition ("That said, ...",
"On the other hand, ...") or just start the next sentence without
the transition word.

### Phrasal templates / placeholder text

If you see "Add your [X] here", "[Your Name] and [Subject]", dates
as "2025-XX-XX" — that's an LLM template that didn't get filled in.
Always replace with real values or cut the section.

## Formatting tells

### Markdown in wikitext contexts

If you're writing to a wiki (MediaWiki, Confluence, etc.), use the
wiki's markup, not Markdown. `# Header` is Markdown; `== Header ==`
is wikitext. AI defaults to Markdown everywhere.

### Emoji as section/bullet decoration

LLMs love to prefix bullets and headings with emoji (📋, ✅, 🎯,
💡, 🔧, etc.). In technical writing, this is a strong tell. Use
emoji only where they're load-bearing (status indicators, error
icons) and never as decoration.

The `language.md` rule already bans emoji in source code, log
strings, error messages, and commit messages. Extend that to
prose: no emoji in README, docs, blog posts, commit bodies, PR
descriptions, code review comments.

### Unnecessary small tables

LLMs create tables for things that read better as prose or as a
list. Two items in a table is almost always a list. A table with
one column of single-word entries is a list.

## Why this rule exists

The em-dash tell is well-documented and easy to spot. The vocabulary
tells are statistically significant in peer-reviewed studies. The
structural tells are what makes a paragraph read as "this was
written by something that learned to write from books, not from
talking to people."

These are **stylistic fingerprints** in the same way a particular
phrasing or repeated word choice is a fingerprint in human writing.
LLMs have one set of fingerprints; humans have many. The point
isn't to be invisible as AI — it's to not be obviously AI on first
read.

When in doubt, read the sentence out loud. If it sounds like a
tutorial, a press release, or a textbook, rewrite. If it sounds
like something you'd say to a coworker, keep it.

## When the user explicitly asks for polished prose

The user might be writing a press release, marketing copy, a
research paper, or a formal letter where the polished register is
exactly the point. In that case:

- The rule is suspended for that specific deliverable
- The code, code comments, and identifiers stay in the working
  register (not polished)
- Match the register the user is asking for, but don't add
  AI-tells on top of it
- If unsure whether the user wants polished or working register,
  ask

## What to skip

These are also on community lists but don't fit engineering /
technical writing:

- "Delve" is fine to avoid in technical writing (already covered
  above) but in fiction, the word sometimes lands well
- "Vibrant" is OK in marketing copy where it means "energetic"
- "Tapestry" can be a real word with a real meaning in historical
  contexts
- Some academic writing genuinely needs "pivotal" or "crucial"
  — the replacement suggestions in this rule are for *technical
  and casual writing*; academic register is a separate style
- Knowledge-cutoff disclaimers ("as of my last training
  update..."): if you catch yourself emitting one, cut it without
  replacement — just deliver the answer

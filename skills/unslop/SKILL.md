---
name: unslop
description: Cut AI tells from writing. Load before writing or editing any prose (docs, README, ADRs, code comments, commit messages, PR descriptions, PR comments, issue text) and to clean up prose that already exists. The user may call /unslop with a file path or pasted text.
argument-hint: "[file path or text to clean up]"
---

<!-- Adapted from https://github.com/cursor/plugins/tree/bc697d0a5a163cec979e362b601e36f5616083fd/pstack/skills/unslop (MIT, see LICENSE). Changes: rules renumbered, comment-narration rules added, invocation and output defined. -->

# Unslop

Remove AI patterns from prose. Keep the meaning and the intended tone.

## How to run it

1. Write or rewrite the text.
2. Scan it against every rule below.
3. Fix each hit.
4. Re-read the result once and confirm it still says what the original meant.

When invoked with a file path, edit the file in place, then report which rules you hit and how many times. When invoked with pasted text, reply with the rewrite only.

Leave these untouched: code, quoted text, CLI output, proper names, and text the user asked to keep verbatim.

## Rules

### Content

1. **Trailing -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...". Delete the phrase or make it its own sentence with a subject and verb.
2. **Vague attributions.** "Experts believe", "Industry reports suggest". Name the source or delete the claim.

### Language

3. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant. Replace with plain words.
4. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Say "is" or "has".
5. **"Not just X, but Y."** State the point directly.
6. **Rule of three.** Don't force ideas into groups of three. Use the natural number.
7. **Synonym cycling.** Pick one term for a thing and repeat it.
8. **False ranges.** "from X to Y" where X and Y are not on a real scale. List the items instead.

### Style

9. **Em dashes.** Never use them. Do not substitute en dashes, hyphens or parentheses. End the sentence or use a comma.
10. **Colons.** Use a colon only before a list or an example, never as a mid-sentence connector.
11. **Bold overuse.** Do not bold proper nouns, acronyms or random phrases.
12. **Inline-header lists.** A bold label and colon that restates the line ("**Performance:** Performance improved...") becomes prose. A bold lead-in that ends in a period, names the item, and is followed by new detail is fine.
13. **Title case headings.** Use sentence case.
14. **Decorative emoji.** Remove them from headings and bullets.
15. **Curly quotes.** Use straight quotes.

### Communication artifacts

16. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!". Remove them.
17. **Sycophancy.** "Great question!", "You're absolutely right!". Respond directly.
18. **Change narration.** In docs and code comments, never describe the edit itself ("added", "fixed", "now uses", "was changed to") or refer to a conversation. State what is true now. The commit message carries the history.

### Filler

19. **Filler phrases.** "In order to" becomes "to". "Due to the fact that" becomes "because". Delete "It is important to note that".
20. **Hedging.** "could potentially possibly be argued that it might" becomes "may".
21. **Generic conclusions.** "The future looks bright." End on a specific fact or plan.

### Jargon

22. **Abstract metaphor nouns.** Substrate, wedge, vector (meaning way), locus, vantage, nexus, primitive as a noun, harness as a metaphor, surface as in "API surface", bedrock, scaffolding as a metaphor, modality, paradigm, gold-plating, ratchet as a metaphor, endgame, north star, flywheel. Use the concrete word.

### Plain speech

23. **Say what it does, not how it feels.** "types that follow your schema" names a feeling. "A column rename fails the build" names the mechanism. If the sentence could appear unchanged in another project's docs, cut it.
24. **One idea per sentence.** If the reader has to reread a sentence, split it or drop clauses.
25. **Active voice.** "Queries are validated" becomes "the compiler validates queries". Passive is fine only when the actor is unknown or does not matter.
26. **Adverbs.** "runs quickly" becomes "is fast" or the measured number. An adverb propping up a verb means the verb is wrong.
27. **Plain words.** "utilize" and "leverage" become "use", "facilitate" becomes "help", "numerous" becomes "many", "in the event that" becomes "if".
28. **Mannered prose.** Aphorisms, rhetorical fragments, personified code ("the plan holds it"), figurative verbs ("rides along"). Say the literal thing.
29. **Over-compression.** Dropped articles, verbless fragments, arrows and abbreviations the reader must decode. "Parser rejects bad date → exit 2, no write" becomes "The parser rejects a bad date, exits with code 2, and writes nothing."

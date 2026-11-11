---
name: grill
description: Interview the user in rounds of numbered questions with recommended answers until every decision in a plan is settled. Use when the user says "grill", "grill me", or asks to stress-test a plan, design or idea. With the argument "docs", also record the decisions in the repo.
argument-hint: "[docs] <plan, issue or topic>"
---

<!-- Adapted from mattpocock/skills grilling, grill-with-docs and domain-modeling (MIT, see LICENSE). Changes: grounding step, round cap, answer shortcuts, summary format, docs mode that follows the repo's own convention. -->

# Grill

Settle every decision in the plan with the user before anything gets built. The decisions are the user's. The facts are yours.

## 1. Ground first

Before the first round, read what the plan touches: the issue, the code, the docs and earlier decisions.

- In an Amedia repo, search Edda (load the `edda:docs` skill) for ADRs and conventions that constrain the plan.
- Send fact lookups to an Explore subagent on Haiku at medium effort. Never ask the user for something you can find in the repo, the tools or the docs.
- A pending lookup blocks only the questions that depend on it. Ask the rest now.

## 2. Ask in rounds

Map the plan as a tree of decisions, where each decision opens the ones that depend on it. A round asks the questions whose prerequisites are settled, at most 8, the most consequential first. Questions that depend on an answer still open in this round wait for a later round.

Format each question like this:

```
**Q1. <short title>**
<the question, with the options as a, b, c when there are options>
Recommended: <the answer you would pick and the reason in one sentence>
```

Word every question so that "yes" accepts the recommendation. End each round with this line: `Reply "all" to accept every recommendation, or "all except Q3: b".`

The user answers as `A1: ...`. Treat "your suggestion", "your recommendation" and "yes" as accepting the recommendation.

## 3. Push back once

If an answer contradicts the code, an earlier decision or an Amedia ADR, say so once, with the file, line or ADR as evidence and the alternative you would pick. If the user keeps the answer, follow it. Keep raising correctness, security and data-loss problems until the user has acknowledged the risk.

When the user uses a term in a different sense than the code or the docs do, name the conflict and ask which meaning is right.

## 4. Finish

The session is done when no unsettled decision remains. Ask once whether anything is missing, then write the summary:

| Decision | Choice | Reason |
|---|---|---|

Follow the table with the open items, each with an owner, and what is out of scope.

Do not change code, create issues or open PRs until the user says so.

## 5. Docs mode

Only when the user passed `docs`. Record decisions in the format the repo already uses: `docs/adr/`, `docs/decisions/`, a glossary file, or whatever the repo's CLAUDE.md or AGENTS.md names. Create files only when there is something to write. If the repo has no convention, ask where decisions should go before writing the first one.

Record a decision only when all three hold:

- It is hard to reverse.
- A future reader would be surprised by it without the context.
- There was a real alternative, and the choice came from a trade-off.

When the repo has no format of its own, use a numbered file (`0001-slug.md`) with a title and one to three sentences: the context, the decision and the reason. Add "Considered options" or "Consequences" only when a future reader needs them.

When a term gets defined during the session, add it to the glossary in the same pass. Docs state the current decision only. When a decision replaces an older one, rewrite or supersede the old record.

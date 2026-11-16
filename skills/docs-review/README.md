# docs-review

Audits a repo's documentation against itself and against the code. It fixes the findings that have exactly one correct fix, then walks the rest one at a time with a drafted fix and options.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

You ask to review the docs, check for doc drift, or make sure the docs are up to date.

It covers README files, docs folders, ADRs and decision docs, CLAUDE.md and AGENTS.md, Edda files, and code comments that assert something.

For docs checked as one part of a wider code review, [deep-review](../deep-review/README.md) runs the [docs-reviewer](../../agents/docs-reviewer.md) agent.

## How to call it

| Call | What runs |
|---|---|
| `/docs-review` | The docs pass, then the code pass |
| `/docs-review docs` | Docs against docs only: contradictions, duplicated decisions, dead pointers, leftover history |
| `/docs-review code` | Docs against code only: wrong descriptions, promises the code does not keep, invariants not enforced everywhere |
| `/docs-review report` | Both passes and the summary, with nothing changed on disk |
| `/docs-review auth billing` | Findings limited to those docs or areas |

You can combine the words, as in `/docs-review report code auth`.

The skill runs in the main context with no subagents, because a contradiction only shows when one context holds both sides. When the docs are too large for one context, it says the size and asks which areas to take first.

## What it changes

- It commits the mechanical fixes as one commit, then each finding you answer as one commit that holds the code and the doc change together.
- On the default branch or a detached HEAD it creates a branch first.
- When tracked files had uncommitted changes at the start, it commits nothing in the run.
- It never commits while a check fails that passed at the start.
- It records a finding you defer where the repo records deferred work.
- With `report` it changes nothing.

## What it needs

In an Amedia repo, the `edda:docs` skill. The org ADRs win over local docs.

## Related skills

[ask-me](../ask-me/README.md) walks the findings. After a `report` run, `/ask-me decide` walks them without edits.

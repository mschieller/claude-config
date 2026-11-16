# grill

Interviews you until every decision in a plan is settled. It asks in rounds of numbered questions, each with a recommended answer, and ends with a table of the decisions.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

- You say "grill" or "grill me".
- You want to stress-test a plan, a design or an idea before anything gets built.

To decide a list of findings that already exists, use [ask-me](../ask-me/README.md).

## How to call it

| Call | What it does |
|---|---|
| `/grill the caching plan` | Settles the decisions and writes the summary |
| `/grill docs the caching plan` | Also records the decisions in the repo, in the format the repo already uses |
| `/grill issues the caching plan` | Also drafts GitHub issues with numbered acceptance criteria |

A mode word counts only at the start of the arguments.

The skill reads the issue, the code, the docs and earlier decisions before the first round, so it never asks for a fact it can look up. It asks each round as plain text, not in dialogs.

You can answer a round in these ways:

- `A1: b` answers one question.
- `all` accepts every recommendation.
- `all except Q3: b` accepts the rest.
- "yes" or "your suggestion" accepts a recommendation.

When an answer contradicts the code, an earlier decision or an ADR, it says so once with the evidence, then follows your answer. It keeps raising a correctness, security or data-loss problem until you have acknowledged the risk.

## What it changes

- Nothing by default. It changes no code, creates no issues and opens no PRs until you say so.
- `docs` mode writes decision records and glossary terms. It records only a decision that is hard to reverse, that would surprise a later reader, and that came from a real trade-off.
- `issues` mode shows every draft first. After you approve, it creates the issues with `gh`, and a milestone when you ask for one.

## What it needs

- `gh`, logged in, for `issues` mode.
- In an Amedia repo, the `edda:docs` skill for the ADRs and conventions that constrain the plan.

## Related skills and agents

- [architecture](../architecture/README.md) hands over a candidate with many open decisions.
- The [spec-reviewer](../../agents/spec-reviewer.md) agent cites the numbered criteria of the issues this skill drafts.

## Credit

Adapted from `grilling`, `grill-with-docs` and `domain-modeling` in [mattpocock/skills](https://github.com/mattpocock/skills), under the MIT license in [LICENSE](LICENSE).

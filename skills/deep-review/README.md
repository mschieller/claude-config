# deep-review

Reviews with several reviewer agents in parallel. The main session checks every finding against the code, scores it from 1 to 100, fixes the mechanical ones, and walks you through the decisions one at a time.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

- You ask for a deep, full or thorough review, or a code scan.
- You want a review after a milestone, or of a plan document before it is built.
- A change is too large for one context. [review](../review/README.md) suggests this skill for a very large change.

For one change on the current branch, use [review](../review/README.md). For a docs audit, use [docs-review](../docs-review/README.md).

## How to call it

| Call | Scope |
|---|---|
| `/deep-review` | The whole repo |
| `/deep-review #123` | That PR's diff |
| `/deep-review branch` | The diff from the merge base with the base branch to the working tree |
| `/deep-review M2` | That milestone's issues against the code |
| `/deep-review src/auth` | That folder |
| `/deep-review docs/plan.md` | The design that document describes |

These can follow the scope:

- `max 4` limits the run to four subagents.
- `report` stops after the report. The skill fixes nothing and walks no decision.
- Any other words are focus areas, such as `performance` or `SQL`. They steer which reviewers run.

## The reviewers

The skill picks reviewers for the scope and the focus words from the agents in [agents/](../../agents). The roster is in step 3 of [SKILL.md](SKILL.md). Each agent file sets its own model and effort. The skill never starts `accessibility-reviewer`.

A project agent with the same name in the repo's `.claude/agents/` wins over the one installed from here.

## What it changes

- It commits the mechanical fixes in logical groups, and each decision you answer as one commit.
- On the default branch or a detached HEAD it creates a branch first.
- When tracked files had uncommitted changes at the start, it commits nothing and leaves the fixes in the tree.
- For a PR scope it checks out the PR's head when the tree is clean, and names the branch it left.
- On a PR that is not yours it edits nothing. The findings you keep become one PR review, posted after you approve the draft.
- It never pushes or opens a PR.

On a long list of decisions it stops partway and asks whether to continue.

## What it needs

- `gh`, logged in.
- The reviewer agents installed in `~/.claude/agents/`, which `install.sh` does.
- In an Amedia repo, the `edda:docs` skill for the ADRs and conventions that apply.

## Related skills

- [ask-me](../ask-me/README.md) walks the decisions.
- [review](../review/README.md) holds the rules for a PR that is not yours.
- [ship](../ship/README.md) takes over when you want a PR.

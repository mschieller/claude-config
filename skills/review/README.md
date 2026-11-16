# review

Reviews one change before it ships. The change is the current branch, seen as its PR when one exists. One context reads the whole change, so the review can see where two files disagree. It reports the findings by severity, fixes the mechanical ones, and walks you through the decisions.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

You say "review", "review the PR", "review my branch" or "review before I ship".

For a whole repo, a milestone, a plan or a very large change, use [deep-review](../deep-review/README.md). When the change is very large, this skill says the size and asks whether to switch.

## How to call it

| Call | What it reviews |
|---|---|
| `/review` | The open PR of the current branch, or the diff from the base branch when there is none |
| `/review #123` | That PR, checked out first when the tree is clean |
| `/review report` | The same change, stopping after the report |
| `/review the migration` | The same change, with the most weight on that focus area |

The review covers the local tree: committed, uncommitted and untracked files. That is what gets pushed next. When the local tree and the pushed PR differ, the report says so.

The report starts with a verdict: ready to ship, ready after the blockers, or not ready.

## What it changes

- It fixes the mechanical findings and runs the repo's checks for the touched files.
- It never commits, pushes or opens a PR.
- It reads the review comments already on the PR to avoid repeating them, and does not act on them. [ship](../ship/README.md) owns those.
- On a PR that is not yours it edits nothing. The findings you keep become one PR review with inline comments, posted after you approve the draft. It posts the review as a comment, never as an approval or a change request unless you say so.

## What it needs

`gh`, logged in. In an Amedia repo, the `edda:docs` skill for the ADRs and conventions that apply.

## Related skills

- [ask-me](../ask-me/README.md) walks the decisions.
- [unslop](../unslop/README.md) cleans the text of a PR review before it is posted.
- [ship](../ship/README.md) takes over when you want a PR.

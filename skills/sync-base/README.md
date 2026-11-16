# sync-base

Brings the current branch up to date with its base branch by merging. It reads what landed on the base and why before it merges, resolves conflicts with both intents understood, then looks for the changes that merge cleanly and are still wrong.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

- You ask to merge main or master in, fix conflicts, or update or sync the branch.
- [ship](../ship/README.md) finds the branch behind its base, or a PR reports a conflict.

`gh stack` updates a branch in a stack by rebasing. This skill stops on such a branch and points to `gh stack sync`, as the stack mode of `ship` describes.

## How to call it

| Call | Base branch |
|---|---|
| `/sync-base` | The PR's base, or the repo's default branch when there is no PR |
| `/sync-base develop` | The branch you name |

Before merging it shows a divergence brief: the files changed on both sides, the incoming commits, and whether the base already built what this branch builds. It pauses only when that last check fails.

After the merge it hunts for semantic conflicts whether or not git reported any. Examples are a symbol the base renamed that the branch still uses, a schema change the branch's queries do not match, and a guard the base added that the branch's new code does not satisfy.

## What it changes

- It makes one merge commit titled `Merge origin/<base> into <branch>`. It fast-forwards a branch that has no commits of its own and makes no commit.
- It fixes plain merge fallout as part of the merge and reports the rest as follow-up work.
- It reinstalls after a lockfile conflict and runs generators for generated files.
- Run on its own, it asks before pushing. Called by `ship`, it returns without pushing.

It never does these:

- Rebase.
- Stash, because worktrees and other sessions share one stash stack.
- Take one whole side of a file that both sides edited.
- Abort the merge and report failure. It resolves the conflict, or stops with the conflicted state intact and says what blocks it.

It asks before merging when an uncommitted change touches a file the merge brings in.

## What it needs

`gh`, logged in, to find the base branch.

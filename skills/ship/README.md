# ship

Takes finished work from the working tree to a pull request with green CI. It runs the checks, commits, opens or updates the PR, watches CI, and fixes failures and the real review findings that are already there. You merge.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

The skill stops at the step your request names.

| You say | What runs |
|---|---|
| "commit" | The checks and the commit |
| "commit and push" or "push the changes" | Through the push, with no PR opened |
| "ship", "create the PR" or "push and create the PR" | Every step, until CI is green |
| "watch the CI" or "CI errored" | The watch and the fixes, on the existing PR |
| "ship as a stack" | Every step, as a chain of PRs made with `gh stack` |

`/ship 42` passes an issue number or other context for the PR.

## What it changes

- It names a new branch `<type>/<slug>`. It renames an existing branch only when the branch has no open or closed PR, no upstream and no type prefix.
- It writes every commit and the PR title as a conventional commit. The repo's own commitlint rules win.
- It pushes and opens a real PR, not a draft, so review bots run. It fills in the repo's PR template when there is one.
- It fixes real CI failures and re-runs a flaky check once.
- It verifies each review comment against the code. For a bot's comment it fixes or declines, replies and resolves the thread. For a person's comment it drafts the reply and posts it only after you approve.
- It declines work outside the PR's goal and lists it as follow-ups.

It never does these:

- Merge, enable auto-merge or push to the base branch, unless you asked in the session.
- Force-push outside stack mode.
- Stash or discard your changes.
- Wait for a review or an approval that has not arrived.

## What it needs

- `gh`, logged in.
- The `gh stack` extension for a stack.
- T3 Code wakes the session when a check finishes or a comment arrives. Elsewhere the skill runs `gh pr checks --watch` in the background.

## Related skills

- [sync-base](../sync-base/README.md) brings the branch up to date when it is behind its base.
- [unslop](../unslop/README.md) cleans the PR body.
- [audit](../audit/README.md) hands over a layer plan for a stack.
- [review](../review/README.md) and [deep-review](../deep-review/README.md) stop before the push and leave the PR to this skill.

## Credit

The PR body and diagram guidance is adapted from `pr` in [mattpocock/skills](https://github.com/mattpocock/skills), which credits Dex Horthy's show-me skill. The review and CI rules are adapted from `file-pr` and `babysit-pr` in [t3dotgg/tstack](https://github.com/t3dotgg/tstack). Both are MIT, and [LICENSE](LICENSE) holds both license texts.

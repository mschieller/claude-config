---
name: ship
description: Take finished work to a pull request that is ready to merge. Runs the checks, commits, opens or updates the PR with a concise body, watches CI and reviews, fixes failures and real findings, and stops when the PR is ready. Never merges unless told. Use when the user says "ship", "create the PR", "push and create the PR", "commit and push", "watch the CI" or "CI errored".
argument-hint: "[issue number or extra context]"
---

<!-- PR body and diagram guidance adapted from mattpocock/skills pr (MIT, see LICENSE), which credits Dex Horthy's show-me skill. Review and CI rules adapted from t3dotgg/tstack file-pr and babysit-pr. -->

# Ship

Own the work from the current working tree to a PR that is ready to merge. The user merges.

Stop at the step the request names. "Commit" stops after step 3. "Commit and push" or "push the changes" stops after the push in step 4, without opening a PR. "Watch the CI" or "CI errored" starts at step 5 on the existing PR. "Ship", "create the PR" or "push and create the PR" runs every step.

## 1. Preflight

- Run `git status --short`. If it shows changes unrelated to the task, ask which to include. Never stash or discard the user's changes.
- Find the base branch: the PR's `baseRefName` if a PR exists, otherwise `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. Never assume `main`.
- If the current branch is the base branch, create a branch named after the change, following the repo's existing branch names.
- Run `git fetch origin`. If the branch is behind the base, bring it up to date with the `sync-base` skill before going further.

## 2. Checks

Run what CI runs, limited to the touched files where the repo allows it: format, lint, typecheck and the tests next to the changes. Find the commands in the repo's CLAUDE.md, AGENTS.md, package scripts or CI workflow. Fix failures before committing. Do not run the full test suite unless CI only offers that.

## 3. Commit

Group the changes into logical commits. Follow the repo's commit title convention; read `git log --oneline -20` to see it. Messages state what changed and why. Add no attribution trailer or "generated with" line.

## 4. Open or update the PR

Check for an existing PR first: `gh pr view --json number,url,state,body`. If one exists, push, and update the body when the scope has changed. If none exists, push with `-u` and open a real PR, not a draft, so review bots run.

Title: follow the repo's convention from recently merged PRs. Say why the change matters, not which mechanism changed.

Body, written with the `unslop` skill and checked for secrets and private details before posting:

```markdown
## Summary

<one or two sentences: the problem, then what this PR does about it>

<optional visual, see below>

- <the changes a reviewer needs to know, as short bullets>

## Verified

<one or two lines: the checks, tests or manual runs that show it works>

**Merge danger:** <only for one-way doors: migrations, data deletion, public API removals, infra changes. Say what cannot be undone and what it affects.>

Closes #<issue>
```

Add a visual only when it shows the reviewer something the bullets cannot: how files moved, a new call path, a state change, or how components interact. Pick the smallest form that makes the point:

- a `diff` sketch of a file tree, a call tree or a component tree when the change adds, moves or removes parts of an existing shape
- pseudocode for a changed algorithm or control flow
- a Mermaid sequence or flow diagram when several services or components talk to each other
- a before and after screenshot for visual changes, when you can upload one

Keep only the files, calls and states the reviewer needs. One visual is normal. Most small PRs need none.

In T3 Code, link the PR to the thread with `link_pull_request`.

## 5. Watch

In T3 Code, call `watch_pull_request` and end your turn. T3 wakes you when a check fails, checks pass, someone comments or reviews, or the branch conflicts. Outside T3, run `gh pr checks <n> --watch` with the Monitor tool. Never write `sleep` or polling loops.

When a wake needs no action, end the turn without a message.

## 6. On each wake

Act only on checks and comments newer than the latest push.

- **Failed check.** Read the failed log with `gh run view <run-id> --log-failed`. Decide whether it is a real failure or an infrastructure flake. Fix real failures, run the checks from step 2, commit and push. Re-run a flake once with `gh run rerun <run-id> --failed`; if it fails again, treat it as real.
- **Conflict or branch behind.** Use the `sync-base` skill, run the checks, and push.
- **Review comment from a bot.** Verify the finding against the code. Fix it when it is real. When it is not, or when it asks for work outside the PR's goal, reply with a one-line reason and resolve the thread.
- **Review comment from a person.** Verify it against the code. Fix it when it is real. Before posting any reply, show the user the draft and post only after approval.

Keep the PR at the size its goal needs. Decline extra tests, guards for cases that do not matter, and refactors the goal did not ask for, and list them as follow-ups in the report.

## 7. Stop

The PR is ready when the required checks pass on the latest commit, no review thread is unresolved, and GitHub reports it mergeable and not behind the base.

Call `unwatch_pull_request` before you stop, also when you stop to ask the user something. Report the PR link, the head commit, the check results, what you fixed along the way, and any follow-ups you declined.

Never merge, enable auto-merge or push to the base branch unless the user asked for it in this session. When asked to merge, run `git fetch`, confirm the PR is still green and not behind, and use the merge method the repo uses. Never bypass branch protection.

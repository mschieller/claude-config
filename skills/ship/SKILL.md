---
name: ship
description: Take finished work to a pull request with green CI. Runs the checks, commits, opens or updates the PR with a concise body, watches CI, fixes failures and the real review findings that are already there, and stops when CI is green. Opens a stack of PRs with `gh stack` when asked for one. Never waits for a reviewer. Never merges unless told. Use when the user says "ship", "create the PR", "push and create the PR", "commit and push", "ship as a stack", "watch the CI" or "CI errored".
argument-hint: "[issue number or extra context]"
---

<!-- PR body and diagram guidance adapted from mattpocock/skills pr (MIT, see LICENSE), which credits Dex Horthy's show-me skill. Review and CI rules adapted from t3dotgg/tstack file-pr and babysit-pr (MIT, see LICENSE). -->

# Ship

Own the work from the current working tree to a PR with green CI. The user merges.

Stop at the step the request names. "Commit" stops after step 3. "Commit and push" or "push the changes" stops after the push in step 4, without opening a PR. "Watch the CI" or "CI errored" starts at step 5 on the existing PR. "Ship", "create the PR" or "push and create the PR" runs every step. A request for a stack, or a layer plan from another skill, runs the steps as [Stack mode](#stack-mode) changes them.

## 1. Preflight

- Run `git status --short`. If it shows changes unrelated to the task, ask which to include. Never stash or discard the user's changes.
- Find the base branch: the PR's `baseRefName` if a PR exists, otherwise `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. Never assume `main`.
- Name the branch `<type>/<slug>`: a conventional commit type (`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci` or `build`) and a kebab-case slug of at most five words that says what the change does, such as `fix/login-redirect-loop`. On the base branch, create it with `git switch -c <name>`. On any other branch, look up its PR with `gh pr view --json state`. If the PR is `OPEN` or `CLOSED`, keep the name, because the PR is tied to it. If there is no PR or it is `MERGED`, rename the branch with `git branch -m <name>`, unless its name already starts with one of those types and a slash. A tool such as T3 may have named the branch that way already. Keep such a name as it is, and do not rename it to get a better slug.

## 2. Checks

Run what CI runs, limited to the touched files where the repo allows it: format, lint, typecheck and the tests next to the changes. Find the commands in the repo's CLAUDE.md, AGENTS.md, package scripts or CI workflow. Fix failures before committing. Do not run the full test suite unless CI only offers that.

## 3. Commit

Group the changes into logical commits. Follow the repo's commit title convention; read `git log --oneline -20` to see it. Messages state what changed and why. Add no attribution trailer or "generated with" line.

## 4. Open or update the PR

Run `git fetch origin`. If the branch is behind the base, bring it up to date with the `sync-base` skill before pushing. The sync runs here, after the commit, because `sync-base` stops when tracked files have uncommitted changes.

Check for an existing PR first: `gh pr view --json number,url,state,body`. The command also returns merged and closed PRs. If an open one exists, push, and update the body when the scope has changed. If none exists or the PR is `MERGED`, push with `git push -u origin HEAD` and open a real PR, not a draft, so review bots run. If step 1 renamed a branch that was already pushed, then delete the old name from the remote with `git push origin --delete <old-name>`. The new name holds the same commits. If the PR is `CLOSED`, ask whether to reopen it or open a new one.

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

Act on failed checks for the head commit, and on every review thread or PR comment that is unresolved and that you have not answered. Ignore a failure on an older commit. On the first wake, start with the comments that were there before the watch began.

`gh pr view` does not show review threads. List the unresolved ones with:

```
gh api graphql -F owner='{owner}' -F repo='{repo}' -F number=<n> -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes { id isResolved path line comments(first: 20) { nodes { author { login } body } } }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)'
```

Resolve a thread with its `id`:

```
gh api graphql -f threadId=<id> -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) { thread { isResolved } }
}'
```

- **Failed check.** Read the failed log with `gh run view <run-id> --log-failed`. Decide whether it is a real failure or an infrastructure flake. Fix real failures, run the checks from step 2, commit and push. Re-run a flake once with `gh run rerun <run-id> --failed`; if it fails again, treat it as real.
- **Conflict or branch behind.** Use the `sync-base` skill, run the checks, and push.
- **Review comment from a bot.** Verify the finding against the code. Fix it when it is real. When it is not, or when it asks for work outside the PR's goal, reply with a one-line reason and resolve the thread.
- **Review comment from a person.** Verify it against the code. Fix it when it is real. Before posting any reply, show the user the draft and post only after approval.

Keep the PR at the size its goal needs. Decline extra tests, guards for cases that do not matter, and refactors the goal did not ask for, and list them as follow-ups in the report.

## 7. Stop

Ship is done when the required checks pass on the head commit. Before you stop, handle the review comments that are already there, as in step 6. A fix starts another CI round. Never wait for a review that has not arrived, and never wait for an approval.

Call `unwatch_pull_request` before you stop, also when you stop to ask the user something. Report the PR link, the head commit, the check results, what you fixed along the way, and any follow-ups you declined.

Never merge, enable auto-merge or push to the base branch unless the user asked for it in this session. When asked to merge, run `git fetch`, confirm the PR is still green and not behind, and use the merge method the repo uses. Never bypass branch protection.

## Stack mode

A stack is a chain of PRs in which each one builds on the one below. The `gh stack` extension creates and updates it. Use this mode when the user asks for a stack, or when a skill hands over a layer plan. A layer plan names each layer from the bottom up: the branch name, its last commit, the PR title and what the body should say. With no plan, propose one and ask before you create branches.

The commits must already be in layer order on the current branch, so that each layer ends at one commit. If they are not, stop and ask, because reordering them rewrites history.

Steps 1 to 3 run as written, with one branch name per layer in the form from step 1. These steps replace step 4:

1. Create each layer's branch at its last commit with `git branch <name> <commit>`. The working branch stays local and is never pushed.
2. Run `gh stack init --base <base> <bottom> ... <top>`. It adopts the branches as a stack.
3. If the base has moved since the branch left it, run `gh stack rebase`.
4. Run `gh stack submit --auto --open`. It pushes every branch and opens one PR per layer, each based on the layer below. `--auto` skips the interactive editor. `--open` makes the PRs ready for review, so review bots run.
5. Set each PR's title and body with `gh pr edit <n> --title <title> --body-file <file>`, in the body format of step 4.
6. In T3 Code, link every PR to the thread.

Steps 5 to 7 run for every PR in the stack, with these differences:

- **A fix.** Put it in the lowest layer it applies to. Check out that branch, commit, run `gh stack rebase --upstack` to carry the fix into the layers above, then `gh stack push`. This rebases and force-pushes with a lease. It is allowed only on the branches of a stack.
- **Base moved, conflict, or a lower layer merged.** Run `gh stack sync` in place of the `sync-base` skill. On a rebase conflict it restores the branches and stops. Then run `gh stack rebase`, resolve each conflict by the rules in step 3 of `sync-base`, and run `gh stack rebase --continue`.
- **Stop.** Ship is done when the required checks pass on the head commit of every layer. Report every PR link, bottom to top.

Never run `gh stack merge` unless the user asked for it in this session.

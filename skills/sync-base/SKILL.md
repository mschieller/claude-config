---
name: sync-base
description: Bring the current branch up to date with its base branch (main, master or the PR's base) by merging. Reads what landed on the base and why before merging, resolves conflicts with both intents understood, then hunts for semantic conflicts git cannot see and runs the repo's checks. Use when the user asks to merge main or master in, fix conflicts, update or sync the branch, or when the ship skill finds the branch behind.
argument-hint: "[base branch, overrides detection]"
---

# Sync base

Merge the base branch into the current branch after understanding what landed on the base since this branch left it, and why. The dangerous part is not the conflicts git reports. It is the changes that merge cleanly and are still wrong.

## Rules

- Merge, never rebase. The branch keeps its history and nothing pushed gets rewritten.
- Know what the base's side of a conflict was for before resolving it. Read the commit that introduced it, not only the hunk.
- Never use `-X ours`, `-X theirs`, or `git checkout --ours/--theirs` on a file where both sides made real edits. Whole-file side-taking is fine only for generated files and for a file one side deleted.
- Never discard the branch's work to make a conflict go away, and never `git merge --abort` and report failure. Resolve it, or stop with the conflicted state intact and explain what blocks you.
- Never merge when an uncommitted change touches a file the merge brings in, and never stash changes away. Worktrees and other sessions share one stash stack, so a pop can take another session's entry.

## 1. Preflight

1. Find the base: the argument when one is given, else the PR's `baseRefName` from `gh pr view --json baseRefName`, else `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. If the current branch is the base, there is nothing to sync.
2. If `gh stack view` lists the current branch, it is in a stack. Stop and use `gh stack sync`, as the stack mode of the `ship` skill describes. A stack is updated by rebasing, and a merge commit breaks that.
3. Find the remote. It is `origin`, unless the repo has none or `origin` is a fork of the repo that `gh repo view --json nameWithOwner` names. Then use the remote in `git remote -v` that points to that repo, and stop if none does. The steps below write `origin` for it.
4. Run `git fetch origin --prune` and work against `origin/<base>`, never a local copy that may be stale.
5. If `git merge-base --is-ancestor origin/<base> HEAD` succeeds, report "already up to date" and stop.
6. Run `git status --porcelain --untracked-files=no`. If it lists a file that `git diff --name-only HEAD...origin/<base>` also lists, ask whether to commit the work first or stop. Ask the same when any change is staged, which `git diff --cached --quiet` shows by failing, because git refuses to merge with a staged change. Other uncommitted changes stay as they are, and git carries them through the merge. Untracked files do not count, because git refuses a merge that would overwrite one.

## 2. Divergence brief

Build this and show it before merging.

- The merge base: `git merge-base HEAD origin/<base>`.
- The overlap set: the files changed on both sides, from `git diff --name-only <merge-base>..HEAD` intersected with `git diff --name-only <merge-base>..origin/<base>`. For each file, what the base changed and why, what the branch changed and why, and whether the intents are compatible, redundant or exclusive.
- The incoming commits from `git log --oneline <merge-base>..origin/<base>`, one line each. Read diffs in depth only for commits that touch the overlap set.
- Two lists recorded while reading: symbols the base renamed or removed, and schema changes (columns, tables, constraints, enum values).
- A premise check. Did the base already build what this branch builds, or change a decision in the docs that this branch implements the old way? If so, say it plainly and ask before merging. Continuing may be wrong.

If nothing in the brief is surprising, merge right after showing it. Pause only for a failed premise check.

## 3. Merge and resolve

Run `git merge --no-ff --no-commit origin/<base>`. Without `--no-commit`, a clean merge commits at once with git's default message, before steps 4 and 5 have run. Classify each conflict:

- **Lockfiles** (`pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `Cargo.lock`, `go.sum`). Take the base's version, then reinstall so the branch's dependency changes are resolved again. The reinstall keeps the base's versions wherever the manifests allow them, so it drops a change the branch made only in the lockfile, such as an audit fix or an update inside a range. Find those commits with `git log <merge-base>..HEAD -- <lockfile>`, run their command again after the reinstall, and confirm that the package manager's audit reports nothing the branch had fixed.
- **Generated files** (route trees, OpenAPI or GraphQL clients, ORM clients, build output, `*.tsbuildinfo`). Take either side, then run the generator. Never hand-merge them.
- **Migrations.** Never hand-merge SQL. Check the ordering even when they merge cleanly: a branch migration may now sort before a base migration it depends on. If it does, regenerate the branch's migration on top of the merged schema with the repo's ORM command. If the base squashed or regenerated its migration chain, regenerate the branch's schema change on top of the new chain.
- **Docs, CLAUDE.md and ADRs.** A conflict here is two decisions, not two texts. Keep each decision in one home doc with its reason, and make the other docs point to it. Registers of independent items, such as decision lists or roadmaps, usually keep both sides' entries; check that neither entry is stale.
- **Everything else.** Keep both sides' intent. Take one side only when the intents are exclusive. When a conflict hides a real design choice that changes behavior, ask with AskUserQuestion: the cause, both intents, the options with the recommended one first. Resolve obvious conflicts yourself.

## 4. Semantic conflict hunt

Run this whether or not git reported conflicts. Start with the repo's typecheck; it finds most of checks 1, 2 and 6 in seconds. Then work through the list, limited to the overlap set and what the branch added or deleted:

1. **Renamed, moved or deleted, in both directions.** Grep the branch's added lines for every symbol on the renamed or removed list. Then grep the base's added lines for everything the branch deleted: files (`git diff --diff-filter=D --name-only <merge-base>..HEAD`), exports and package entry points. A typecheck can pass while a bundler or test runner still fails on a removed package export.
2. **Changed signatures and shapes.** New required parameters, narrowed types, changed return shapes and widened unions that the branch handles only in part.
3. **Schema against queries.** The schema changes from step 2 against the queries and inserts the branch wrote, plus the migration ordering from step 3.
4. **New invariants.** Guards, permission checks, lint rules, validation or required fields the base added that the branch's new code does not satisfy. Read the guard's own source to see what it matches before searching for violations.
5. **Work done twice.** Both sides solved the same problem. Keep one implementation and say which and why.
6. **Config and environment.** New env vars, config keys, service definitions and changed script bodies. If the base wrapped a tool in a script, branch code that still calls the tool directly now skips the wrapper.
7. **Fixtures, seeds and test helpers** whose shape the base changed. A branch test that passes against a stale fixture is a false green.
8. **Docs decisions against the branch's code.** Where the base changed a decision, fix the branch's code when it is a spot fix, and report it otherwise. Where the base moved a decision to another doc, grep the branch's comments and docs for pointers to the old place.

Each hit is fixed as part of the merge when it is plain merge fallout, or reported as follow-up work. Say which for each hit.

## 5. Verify

Run the repo's checks in order of cost, as its CLAUDE.md, AGENTS.md or package scripts name them: typecheck, lint, format, then the tests for every package the merge touched. Run database or migration tests when anything under the schema or migrations changed. Fix what the merge broke.

When a check fails for a reason unrelated to the merge, check whether it fails on the base too, and report it as such.

## 6. Commit and report

Stage the resolutions and the fixes from step 4 by path, never with `git add -A`, so that changes the user left uncommitted stay out. Commit the merge with `git commit -m`. The message says what came in and how the non-obvious conflicts were resolved, not only `Merge branch 'main'`.

Report:

- what landed from the base, summarized
- every conflict and how it was resolved, with the intent kept from each side
- every semantic hit, fixed or reported as follow-up
- check results, including anything still failing and why

Run on its own, ask before pushing. When the `ship` skill called this skill, return to ship without pushing. Ship owns the push.

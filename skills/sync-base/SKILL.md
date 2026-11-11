---
name: sync-base
description: Bring the current branch up to date with its base branch (main, master or the PR's base) by merging. Reads what landed on the base and why before merging, resolves conflicts with both intents understood, then hunts for semantic conflicts git cannot see and runs the repo's checks. Use when the user asks to merge main or master in, fix conflicts, update or sync the branch, or when the ship skill finds the branch behind.
argument-hint: "[base branch, only when it cannot be detected]"
---

# Sync base

Merge the base branch into the current branch after understanding what landed on the base since this branch left it, and why. The dangerous part is not the conflicts git reports. It is the changes that merge cleanly and are still wrong.

## Rules

- Merge, never rebase. The branch keeps its history and nothing pushed gets rewritten.
- Know what the base's side of a conflict was for before resolving it. Read the commit that introduced it, not only the hunk.
- Never use `-X ours`, `-X theirs`, or `git checkout --ours/--theirs` on a file where both sides made real edits. Whole-file side-taking is fine only for generated files and for a file one side deleted.
- Never discard the branch's work to make a conflict go away, and never `git merge --abort` and report failure. Resolve it, or stop with the conflicted state intact and explain what blocks you.
- Never merge over a dirty tree.

## 1. Preflight

1. Find the base: the PR's `baseRefName` from `gh pr view --json baseRefName`, else `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`, else the argument. If the current branch is the base, there is nothing to sync.
2. Run `git status --porcelain`. If the tree is dirty, ask whether to commit or stash. A stash taken here is popped in step 6.
3. Run `git fetch origin --prune` and work against `origin/<base>`, never a local copy that may be stale.
4. If `git merge-base --is-ancestor origin/<base> HEAD` succeeds, report "already up to date" and stop.

## 2. Divergence brief

Build this and show it before merging.

- The merge base: `git merge-base HEAD origin/<base>`.
- The overlap set: the files changed on both sides, from `git diff --name-only <merge-base>..HEAD` intersected with `git diff --name-only <merge-base>..origin/<base>`. For each file, what the base changed and why, what the branch changed and why, and whether the intents are compatible, redundant or exclusive.
- The incoming commits from `git log --oneline <merge-base>..origin/<base>`, one line each. Read diffs in depth only for commits that touch the overlap set.
- Two lists recorded while reading: symbols the base renamed or removed, and schema changes (columns, tables, constraints, enum values).
- A premise check. Did the base already build what this branch builds, or change a decision in the docs that this branch implements the old way? If so, say it plainly and ask before merging. Continuing may be wrong.

If nothing in the brief is surprising, merge right after showing it. Pause only for a failed premise check.

## 3. Merge and resolve

Run `git merge origin/<base>`. Classify each conflict:

- **Lockfiles** (`pnpm-lock.yaml`, `package-lock.json`, `yarn.lock`, `Cargo.lock`, `go.sum`). Take the base's version, then reinstall so the branch's dependency changes are resolved again.
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

If step 1 stashed, commit the merge first, then `git stash pop` and resolve whatever the pop raises with the same rules. Report the restore.

The merge commit message says what came in and how the non-obvious conflicts were resolved, not only `Merge branch 'main'`.

Report:

- what landed from the base, summarized
- every conflict and how it was resolved, with the intent kept from each side
- every semantic hit, fixed or reported as follow-up
- check results, including anything still failing and why

Run on its own, ask before pushing. When the `ship` skill called this skill, push and return to ship.

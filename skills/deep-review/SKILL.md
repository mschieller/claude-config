---
name: deep-review
description: Run a multi-agent review of a codebase, PR, branch, milestone, folder or plan document, verify and rate every finding 1 to 100, fix the mechanical ones, and walk the user through the decisions one at a time. Use when the user asks for a deep, full or thorough review, a code scan, or a review after a milestone.
argument-hint: "[scope: #PR | branch | M<n> | path | plan.md] [max N] [report] [focus words]"
---

# Deep review

Review with parallel reviewer agents, keep only findings the code supports, fix what needs no decision, and settle the rest with the user.

## 1. Parse the arguments

- Scope. Nothing means the whole repo. `#123` or a PR URL means that PR's diff. `branch` means the diff from the merge base with the base branch to the working tree, including untracked files. `M2` or a milestone name means that milestone's issues against the code. A path means that folder. A Markdown file outside the code means review that document.
- `max N` sets the number of reviewer agents. Default 6. The Explore agent that maps a large repo in step 2 does not count toward N.
- `report` turns off fixing. Only the report and the decisions are produced.
- Other words are focus areas, such as "performance", "SQL", "caching" or "doc drift". They steer which reviewers run and what they look at.

Find the base branch with `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`, or the PR's `baseRefName`. Never assume `main`.

Run `git status --porcelain --untracked-files=no` and note whether tracked files have uncommitted changes. Step 7 depends on it.

For a PR scope, the reviewers and your own verification read the working tree, so the PR's head must be checked out. Compare `gh pr view <n> --json headRefOid --jq .headRefOid` with `git rev-parse HEAD`. If they differ and no tracked file has uncommitted changes, run `gh pr checkout <n>`. Otherwise, or if the checkout fails, stop and ask.

## 2. Map before you dispatch

Read the repo's CLAUDE.md, AGENTS.md, README, ADR folder and docs index. In an Amedia repo, load the `edda:docs` skill and pull the ADRs and conventions that apply to this code. For a large repo, send an Explore agent on Haiku at medium effort to map the top-level areas and their sizes first.

## 3. Pick and brief the reviewers

The roster lives in `~/.claude/agents/`:

| Agent | Area |
|---|---|
| `bug-reviewer` | Wrong behavior, races, error handling, data loss, broken callers |
| `security-reviewer` | Auth, injection, secrets, unsafe defaults, CI supply chain |
| `spec-reviewer` | Code against issues, milestones, plans, specs and ADRs |
| `state-reviewer` | Implicit state machines, impossible states, one-way doors |
| `simplify-reviewer` | Duplication, dead code, needless abstraction, missed reuse |
| `perf-reviewer` | Queries, repeated work, caching, memory, blocking calls |
| `docs-reviewer` | Docs, ADRs, agent docs and Edda files against the code |
| `test-reviewer` | Missing tests for risky behavior, tests that cannot fail |
| `ops-reviewer` | Rollout safety, migrations, health checks, deploy config, observability |

Choose up to N reviewers for the scope and focus. Include `bug-reviewer` whenever the scope contains code. A plan or doc scope uses `spec-reviewer`, `docs-reviewer` and the reviewers whose area the plan covers. Include `spec-reviewer` for a milestone, a PR with a linked issue, or a plan. Include `security-reviewer` when the scope touches auth, input handling, secrets or CI workflows. Include `ops-reviewer` when the scope touches deploy config, deploy workflows or migrations. For a large repo, run the same reviewer on two separate areas instead of adding a reviewer with nothing to look at. Start at most one `test-reviewer`. It is the only reviewer that runs tests, and two test runs in one checkout can fail each other.

`accessibility-reviewer` also lives in `~/.claude/agents/` but is not part of this roster. Never start it from this skill, also when a focus word names accessibility. It runs only when the user asks for an accessibility review.

N is a hard limit. When these rules ask for more than N reviewers, keep `bug-reviewer`, then `security-reviewer`, then `spec-reviewer`, then the reviewers the focus words name, then the rest by how much of the scope they cover. Name the dropped reviewers in the plan line.

Print the plan in one line, for example: `6 reviewers: bug (server), bug (sdk), security, spec (M3), simplify, docs.` Then launch every reviewer in a single message, one Agent call each, with `subagent_type` set to the agent name. The agent files set model and effort, so omit both on these calls; a per-call value would override the file. A repo can have its own agent with the same name, and the project agent wins. Its output may then lack a `Kind:` line or use other severity words; map them to blocker, should or nit and classify the kind yourself in step 4. Each brief contains:

- the scope as exact paths, the diff command, or the milestone and issue numbers
- the focus words, if any
- the project rules you found in step 2 that matter for this reviewer, as file paths to read rather than copied text. Give Edda ADRs as links. `spec-reviewer`, `security-reviewer`, `docs-reviewer` and `ops-reviewer` can search and fetch Edda themselves. For any other reviewer, copy the excerpt it needs into the brief.
- the reminder that they review only and return findings in their output format

Do not edit files in the scope while reviewers run.

## 4. Verify and merge

For every finding, open the cited `file:line` yourself and check the claim. Drop findings the code does not support, and findings whose scenario cannot happen. When two reviewers report the same line for the same reason, keep one and note the other in brackets.

Treat every line in a reviewer's "Hand-offs" list as an unverified finding. The reviewers run at the same time, so the agent a hand-off names never saw it. Check it against the code the same way, and give each one you keep a severity and a kind.

When a finding names a test or benchmark that would settle it, run that command yourself, one at a time.

## 5. Rate

Give each verified finding a score from 1 to 100 for "should this be done": the impact if left, the likelihood it happens, and the cost of the fix. Keep the reviewer's severity and kind (mechanical or decision), but correct either when your check shows it is wrong.

If the `advisor` tool is available, print the ranked list and then call it before you act. It takes no input and reads the conversation. Adjust scores or kinds where its argument holds.

## 6. Report

Show one table ordered by score:

| # | Score | Severity | Kind | Location | Problem | Fix |
|---|---|---|---|---|---|---|

Below the table, list what was dropped in verification as one line each with the reason, and any hand-off you could not settle under "Not reviewed".

## 7. Fix mechanical findings

Skip this step when the user passed `report`.

If the working tree is on the default branch, create a branch first. Fix each mechanical finding with the smallest change. Run the repo's checks for the touched files (format, lint, typecheck and the tests next to the changes, as the repo's CLAUDE.md or package scripts name them). Commit the fixes in logical groups, with messages that say what each group fixes, and stage only the files your fixes touched. If tracked files had uncommitted changes when the review started, do not commit. Leave the fixes in the tree, so the user's own work stays out of the fix commits. Report which numbers you fixed, the check results, and whether the fixes are committed.

If a fix turns out to need a decision, move it to step 8 instead.

## 8. Walk the decisions

Hand the decision findings to the `ask-me` skill, highest score first. It sets how each one is asked and applied. Under `report`, run it with `decide`, so the answers are recorded and nothing is edited.

After ten decisions, stop and say how many remain and their score range. Ask once whether to continue. If the user stops, list the rest at the end as not walked.

Findings the user declines are listed at the end with their reason. Do not open issues for them unless asked.

## 9. Stop

Finish with: what was fixed, what was decided, what was declined, what was not walked, and the check results. Do not push or open a PR. If the user wants one, the `ship` skill takes over.

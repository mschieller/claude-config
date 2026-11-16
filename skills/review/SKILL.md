---
name: review
description: Review the change on the current branch before it ships. Takes the open PR when one exists, otherwise the diff from the base branch to the working tree. Reads the whole change in one context, checks it against its intent, verifies every finding, reports them by severity, fixes the mechanical ones, and walks the decisions with the ask-me skill. Use when the user says "review", "review the PR", "review my branch" or "review before I ship". A PR number or URL in the arguments is checked out first. On a PR that is not yours it edits nothing and drafts a PR review with inline comments, posted after you approve. For a whole repo, a milestone, a plan or a very large change, use deep-review.
argument-hint: "[#PR] [report] [focus words]"
---

# Review

Review one change before it ships: the current branch, seen as its PR when one exists. One context reads the whole change, so the review can see where two files disagree. No subagents.

## 1. Find the change

- `report` in the arguments stops after the report. Other words are focus areas, such as "error handling" or "the migration".
- `#123` or a PR URL in the arguments names the PR to review. When it is not the PR of the current branch, run `gh pr checkout <n>` if no tracked file has uncommitted changes, and say which branch you left. Otherwise stop and ask. Name the branch you left again in the report.
- Look up the PR for the current branch with `gh pr view --json number,url,state,title,body,author,baseRefName,headRefOid,closingIssuesReferences`. An `OPEN` PR gives the base branch, the stated intent and the linked issues. The PR is yours when its `author.login` is one of the accounts logged in to `gh`, which `gh auth status --json hosts --jq '.hosts[][].login'` lists, or when `author.is_bot` is true. Any other PR is someone else's. Nothing is edited then, and the findings become a PR review in step 9. With no PR, or one that is `MERGED` or `CLOSED`, find the base with `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. Never assume `main`.
- Run `git fetch origin`. When `origin` is a fork of the PR's repo, use the remote that points to that repo in its place. The change is everything from `git merge-base HEAD origin/<base>` to the working tree. `git diff <merge-base>` shows the committed and uncommitted edits, and `git ls-files --others --exclude-standard` lists the untracked files.
- If nothing differs from the base, say so and stop.
- With an open PR, compare `headRefOid` with `git rev-parse HEAD`. Note for the report when the local tree holds work that is not pushed, or when the PR head has commits the local branch lacks. The review covers the local tree, because that is what gets pushed next.
- Count the size with `git diff --numstat <merge-base>`, leaving out lockfiles and generated files. Above about 1,500 changed lines or 40 files, say the size and ask whether to continue here or switch to the `deep-review` skill.

## 2. State the intent

Write one or two lines on what the change is meant to do. Take it from the PR title and body, the linked issues and their acceptance criteria (`gh issue view <n>`), the commit messages and the request in this conversation. If none of them says, state the intent you read from the diff and mark it as inferred.

## 3. Read

- The repo's CLAUDE.md and AGENTS.md, and the ADRs or docs that cover the changed area. In an Amedia repo, load the `edda:docs` skill and pull the ADRs and conventions that apply.
- The whole diff, then every changed file in full. A hunk without its file hides what the change broke around it.
- The callers and users of every function, type, route, schema or config key the change touched. Search for them. Do not assume.
- With an open PR, the review comments already there: `gh api --paginate repos/{owner}/{repo}/pulls/<n>/comments --jq '.[] | {path, line, user: .user.login, body}'`. Do not report what a comment already raises, and do not act on comments. The `ship` skill owns them.

## 4. Review

Go through the change once per lens, and give the focus words the most weight.

- **Correctness.** Wrong results for real inputs, including empty, missing and boundary values. Callers that still use the old shape. Errors that are swallowed or retried wrongly. Partial writes and lost data. Races between requests, retries and async work. Casts, disabled lint rules and suppressed type errors that hide a real error or state no reason.
- **Security.** Routes or actions without a permission check, trust in client-supplied IDs or headers, injection, request forgery, and secrets or personal data in code or logs.
- **Intent.** Each thing the intent or an acceptance criterion asks for, on every entry point. Behavior that differs from what was asked. Work nobody asked for.
- **Tests.** Changed behavior that can break with every test still green. Tests that cannot fail. Tests at the wrong layer.
- **Simplicity.** Duplication, dead code the change left behind, an abstraction with one caller, and code that rebuilds what the framework, a dependency or the repo already has.
- **Docs and comments.** Docs, READMEs, ADRs and doc comments the change made wrong. Comments that restate the code, describe the edit or leave a `TODO`.

Add a lens only when the change touches its ground: performance for queries, loops and caches, state for status fields and flag combinations, deploy for migrations, deploy config and workflows.

## 5. Verify

For every finding, open the `file:line` again and build the concrete case: the input or state that triggers it, and what goes wrong. Drop a finding you cannot show.

Run the repo's checks for the touched files, as its CLAUDE.md, AGENTS.md or package scripts name them: format, lint, typecheck and the tests next to the changes. Do not run the full suite.

Give each finding a severity. blocker means the intended case is wrong, data is lost, or a hole is open to an outsider. should means a real problem that users, callers or the next developer will hit. nit means everything else.

Give each finding a kind. It is mechanical when exactly one fix is correct and the fix changes no behavior anyone relies on, no public API, no schema and no design. Everything else is a decision. When in doubt, it is a decision.

## 6. Report

Start with one verdict line: ready to ship, ready after the blockers, or not ready, with the count per severity. Then:

- the intent you reviewed against
- where the local tree differs from the pushed PR, if it does
- one table ordered by severity

| # | Severity | Kind | Location | Problem | Fix |
|---|---|---|---|---|---|

- the check and test results
- what you checked and found sound, named by area, so a clean area reads as verified
- what you did not review, and why

If there are no findings, say so in one line and stop. When the user passed `report`, stop here.

## 7. Fix mechanical findings

When the PR is someone else's, go to step 9.

Fix each mechanical finding with the smallest change, and run the repo's checks for the touched files. Do not commit. Say which numbers you fixed and what the checks showed. If a fix turns out to need a decision, move it to step 8.

## 8. Walk the decisions

Hand the decision findings to the `ask-me` skill in table order. It sets how each one is asked and applied, and it never commits. After the walk, finish with what was fixed, what was left as it is, and the check results. Do not push or open a PR. If the user wants one, the `ship` skill takes over.

## 9. A PR that is not yours

Edit nothing. Hand every finding to the `ask-me` skill with `decide`, in table order. Each dialog chooses between posting the finding as a comment and dropping it.

Draft one review from the findings the user kept. The comments point at lines of the PR head, so when step 1 found that the local tree differs from it, stop and ask before drafting. A finding on a line the PR's diff contains becomes an inline comment on that line. Any other finding goes into the review body with its `file:line`. Each comment states the problem, the concrete case and the suggested fix. Write the text with the `unslop` skill and check it for secrets and private details.

Show the whole draft and post it only after the user approves. Write the review to a JSON file and post it with `gh api repos/{owner}/{repo}/pulls/<n>/reviews --input <file>`:

```json
{
  "commit_id": "<headRefOid>",
  "event": "COMMENT",
  "body": "<a one-line summary, then the findings without a line in the diff>",
  "comments": [{ "path": "src/a.ts", "line": 42, "side": "RIGHT", "body": "<the comment>" }]
}
```

Keep the event `COMMENT`. Approve or request changes only when the user says so. Report the review's URL.

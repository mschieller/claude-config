---
name: docs-review
description: Audit a repo's documentation against itself and against the code, fix the mechanical findings, then walk the rest one finding at a time with a drafted fix and options. Covers README, docs folders, ADRs and decision docs, CLAUDE.md and AGENTS.md, Edda files and code comments that assert something. Use when the user asks to review the docs, check for doc drift, or make sure the docs are up to date.
argument-hint: "[docs | code] [doc names or areas, empty means all]"
---

# Docs review

Find where the documentation disagrees with itself or with the code, then settle each finding with the user and apply it.

## Rules

- Run in the main context. Do not start subagents. Contradictions only show when one context holds both sides.
- Docs record decisions. Code records facts. Establish what the system does by reading code, never by trusting a doc's description of it.
- Anchor every finding on both sides: `docs/auth.md:42` against `src/auth/guard.ts:88`, or two doc locations. No finding from memory or inference.
- Docs and comments state current truth only. No history, dates, "was previously" or rejected-option debate. The reason for the chosen decision stays.
- Respect settled decisions. Flag a decision that is vague, contradictory or not followed. Propose replacing a sound decision only under the improvement bar in the docs pass.
- In an Amedia repo, the org ADRs in Edda win over local docs. Load the `edda:docs` skill and check local decisions against them.

## 1. Scope

- No mode: run the docs pass, then the code pass.
- `docs` or `code`: run that pass only.
- Doc names or areas narrow the findings to those docs or areas. Still read the other docs, because a contradiction needs both sides in view.

Run `git status --porcelain --untracked-files=no` and note whether tracked files have uncommitted changes. The commit rules in steps 5 and 6 depend on it.

Read the repo's CLAUDE.md and AGENTS.md first. They name the docs layout, the working principles and any status tracking (status lines, a roadmap with open decisions, a decision register).

Build the known-deferred list from wherever the repo records deferred work. Exclude those items from findings and confirm them in one line in the summary. A deferred item becomes a finding only when its recorded status is now wrong.

## 2. Docs pass: docs against docs

Read every doc in scope in full. Look for:

1. The same fact or decision stated differently in two places.
2. Leftover debate: rejected alternatives, review commentary, session narrative, change history, dates.
3. Decisions that are vague, contradict themselves, or lack the detail needed to build from them.
4. Decisions the project clearly needs that no doc makes.
5. One decision recorded in more than one doc. Other docs point to the home doc and never paraphrase it.
6. Pointers to sections or files that moved or no longer exist.
7. Status lines that are missing, or that disagree between the home doc and the register or roadmap.
8. Decisions that contradict the working principles in CLAUDE.md or AGENTS.md.
9. A materially better approach to a settled decision. Raise it only when all four hold: a large concrete gain in cost, risk, security or simplicity; a new basis the original decision did not weigh; a switching cost the gain justifies; and agreement with the repo's principles. If any test is uncertain, stay silent. Most reviews have zero of these.

## 3. Code pass: docs against code

Read the doc for an area in full before opening its code, so the expectation forms first. Then read the code once per file and check every point together:

1. The doc describes the system wrongly, with no design question involved.
2. The code had to invent something the doc left open, and the next builder would invent it differently.
3. The doc says X and the code does Y. Argue which side is right.
4. The doc promises something the code does not do. Separate deliberately deferred work from work that silently never landed.
5. The code does something the docs never mention. Document it only when a future reader would otherwise reopen the decision or build on a wrong assumption.
6. A feature implemented on one entry point but not its siblings: one app but not the other, one router but not the rest. List the full set and check each member.
7. Invariants the docs state as "every X has Y", such as permission checks, tenant scoping, audit rows or validation. Check every member of the set. One unenforced member is high severity.
8. A stated guarantee with no test that would fail if it broke.
9. A doc noun and a code identifier for the same concept that have drifted apart.
10. Code comments that assert something checkable and are wrong, that restate a doc decision instead of pointing to it, or that narrate history.
11. Edda index files and published docs that describe behavior the code no longer has.

Before reporting something as missing, grep at least two naming variants, check the sibling package or app, and check the tests. If it is still missing, say which searches you ran.

## 4. Mechanical fixes during the sweep

Fix findings with exactly one correct fix right away: a pointer to a renamed file, a stale section reference, a leftover date, a typo, a comment whose removal loses nothing. List them in the summary as done. Anything that needs judgment goes to the walk-through. When in doubt, it is not mechanical.

## 5. Summary

Show one table ordered by severity: number, severity, pass, both anchors, a one-line gist, and for code-pass divergences the likely side (doc, code or both). High severity means security, data integrity, tenant isolation, or code that breaks a recorded decision. Medium means a doc that will mislead the next builder, or a spec that silently did not land. Low means naming, wording or comment quality.

Below the table:

- Mechanical fixes already applied.
- Still deferred, unchanged: the one-line confirmation.
- Checked and aligned: the areas that match, named, so a clean area reads as verified.
- Improvement proposals from docs pass point 9, in their own section, each naming the decision it challenges.

Then run the repo's checks and commit the mechanical fixes as one commit, so each later commit holds one finding. Stage only the files you changed. If you are on the default branch, create a branch first. If tracked files had uncommitted changes at the start, commit nothing in this run, here or in step 6, and say so in the wrap-up.

If there are no findings and nothing was fixed, report "No findings", list the aligned areas, and stop.

## 6. Walk the findings

Hand the findings to the `ask-me` skill in table order. It sets how each one is asked and applied. These rules add to it.

The outline for each finding also holds:

1. Both anchors, quoted.
2. For a divergence, the argument: what the doc's version gives, what the code's version gives, and which principle decides it. The verdict is "the doc is stale", "the code is a bug", or "both are wrong" with a third design.
3. The drafted fix, written out: doc text, code change, comment rewrite or the missing test.

Every dialog also has a defer option.

For an improvement proposal, show the current decision and its recorded reason fairly first, then the improvement, the new basis that justifies reopening it, and the decisions that depend on it and would have to move too.

Applying an answer means all of this, before the next finding:

- Change the code and the doc together.
- Update the home doc only, and update any status line, register or roadmap the repo keeps.
- Record a deferred item where the repo records deferred work.
- Run the repo's checks for what changed. Never commit while a check fails.
- Commit the finding as one commit containing all its edits. Nothing is committed for "Leave as is" or "defer". If you are still on the default branch, create a branch first.

## 7. Wrap up

Summarize what changed per file, the commits made, what was deferred and where it was recorded, and anything left to follow up. If a settled decision was replaced, say so first and list the dependent decisions that moved with it.

---
name: architecture
description: Find restructuring opportunities and present them as a visual report of candidates, then settle and build the ones the user picks. Default mode looks for shallow modules to deepen in the code. The "drastic" mode widens to the service, SDK, UX, DX and operations. Use when the user asks how to improve a codebase's architecture, where to restructure, or "if we were to do something drastic".
argument-hint: "[drastic] [area, folder or PR]"
---

<!-- Adapted from mattpocock/skills improve-codebase-architecture and codebase-design (MIT, see LICENSE). Changes: inline report delivery, drastic mode, decisions through AskUserQuestion, build hand-off to ship. -->

# Architecture

Propose restructurings that make the code easier to change, test and navigate, then settle the chosen ones with the user. Use the vocabulary in [VOCABULARY.md](VOCABULARY.md) exactly: module, interface, depth, seam, adapter, leverage, locality. These are defined terms, so the plain-words rules in CLAUDE.md and `unslop` do not replace them. Read it before the scan.

## 1. Scope

- An area, folder or PR in the arguments limits the scan to that. For a PR, look only at what the PR added or changed.
- Without one, run `git log --oneline -200 --name-only` and weight the files and areas that change most. Changes that keep landing in the same place are where a better structure pays back.
- Read the repo's CLAUDE.md, AGENTS.md, glossary and ADRs. In an Amedia repo, load the `edda:docs` skill for the org ADRs and conventions. Recorded decisions are not reopened unless the friction is large enough to justify it.

## 2. Scan

Send an Explore agent on Haiku at medium effort to map the scoped area: modules, their sizes, who calls whom, and where tests sit. Judge the friction yourself in the main session:

- One concept that needs a reader to jump between many small modules.
- Shallow modules whose interface is nearly as complex as their implementation.
- Pure functions extracted for testability while the bugs live in how they are called.
- Modules that reach across their seams into each other's internals.
- Behavior that is untested, or hard to test through its current interface.

Apply the deletion test to anything that looks shallow: if deleting it would concentrate complexity in one place, it is a candidate. If it would spread complexity across callers, it earns its keep.

### Drastic mode

With `drastic`, widen the question to "what change would most improve this service for its users and developers". Look at the service's design, the SDK or client experience, the UX of any UI, developer experience (setup, scripts, CI time, release flow), operations (deploy, observability, scaling against the real traffic) and integrations with the rest of the org. Ground each idea in the code, docs or measured facts, and say what it costs. Bold ideas are welcome when they hold up.

## 3. Report

Build one self-contained HTML report with a card per candidate:

- Files involved
- Problem: the friction the current structure causes
- Solution: what would change, in plain words. No interface design yet.
- Benefit: in terms of locality, leverage and how tests improve
- A before and after diagram (Mermaid for graphs and sequences, simple HTML boxes for module shapes)
- Strength: strong, worth exploring or speculative
- An ADR warning when the candidate contradicts a recorded decision, with the reason to reopen it

End with a top recommendation: the candidate to take first and why.

In T3 Code, show the report inline with `html_preview` and then `html_render`, using T3's theme variables, so it is readable on a phone. Also save it to the session's scratchpad folder, or `$TMPDIR` outside a session with one, and give the path. Outside T3, open the saved file. Save it into the repo only when the user asks.

Then ask which candidates to explore.

## 4. Explore

For each candidate the user picks, expand it: the dependencies and their category, where the seam goes, what moves behind it, which tests survive and which get replaced. Update the card in the report.

When the interface shape is open, offer "design it twice": start three Agent calls on Opus at high effort in one message, each with a different constraint. One minimizes the interface to one to three entry points. One optimizes for the most common caller. One designs around ports and adapters. Compare the designs on depth, locality and seam placement, then recommend one or a hybrid.

## 5. Decide

Settle the open decisions of each picked candidate with the `ask-me` skill in `decide` mode, because nothing is built before step 6. When a candidate has more than about six open decisions, hand over to the `grill` skill instead. Neither skill ends this one. When it is done, list the decisions for that candidate, update its card, and go on to the next picked candidate.

When the user rejects a candidate for a reason a future review would need, offer to record it as an ADR in the repo's format, so later runs do not suggest it again.

## 6. Build

Change no code until the user says to build. Then implement one candidate at a time, test through the new interface, replace the tests that tested past it, run the repo's checks, and commit. Hand over to the `ship` skill when the user wants a PR.

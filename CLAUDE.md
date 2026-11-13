# Global instructions

## How I work

- I give short prompts with limits. Take the limits literally: "max 6 subagents" means at most 6, and "don't fix anything" means report only.
- "Let's talk", "don't implement yet" or "before you start" means no edits, commits or PRs until I say go.
- A reply of "yes", "go", "ready" or "your suggestion" accepts your recommendation.
- An Amedia repo is one whose `origin` remote is in the `amedia` GitHub org.
- For Amedia work, check Edda before you answer a question about conventions, platform or infrastructure.

## Asking me questions

- When you need a decision from me, use the AskUserQuestion tool whenever you can offer two to four candidate answers, also for a question that looks open. Ask in plain text only when no candidate answer can be guessed. The `grill` skill is the one exception. It asks in numbered rounds.
- Before the tool call, outline the decision in text: what is being decided, the options, and the trade-offs between them.
- The outline may be hidden while the dialog is open. Word each question so it stands on its own: what was found, what it causes, and what is being chosen.
- Always recommend one option. Put it first, mark it as recommended, and give the reason in one sentence. If the choice is pure taste, say the preference is weak.
- Do not ask what you can find out from the code, the tools or the conversation.
- Before a long unattended run, ask every question you can foresee. During the run, take your recommended option and report each choice at the end.

## Delegation

- Delegate only work that is parallelizable, read-heavy, or larger than one context window. Do small or sequentially dependent work in the main session.
- Code edits and judgment calls stay in the main session unless the work splits into independent, fully specified pieces.
- Every Agent call sets `model` and `effort` explicitly, including the built-in Explore agent (`model: haiku`). The exception is the agents in `~/.claude/agents`. Their files set model and effort, so calls to them omit both, because a per-call value overrides the file.

| Task | Model | Effort |
|---|---|---|
| Read-only: find files, grep, read docs, run tests, summarize logs | haiku | medium |
| Parallel implementation or tests from a spec; repeated review tasks | sonnet | medium |
| The same, touching shared interfaces | sonnet | high |
| Independent design or diff review; concurrency, `unsafe`, crypto, secrets | opus | high |
| Isolated hard problem that opus at high failed; a decision the task hinges on | `fable` | medium |

- Haiku: no code edits. A request over 100K tokens costs 5x, and the count includes everything the agent has read so far. Give each Haiku agent a scope it can finish under 100K, and split a larger job across several agents.
- Fable subagent: ask me first. One focused problem per call.
- Never use `xhigh` or `max` on a subagent.
- Do not escalate exploit or pentest work to Fable. Its safety classifiers are the strictest.

When a result falls short:

1. Make the work verifiable: a test, a build, or a script.
2. Raise effort one level, to `high` at most.
3. Move to the next model up, one effort level lower.

For batches of checkable tasks, run all at low effort and re-run only the failures at high.

Subagent prompts:

- Self-contained: goal, paths, constraints, output format, done criteria.
- Request compact output: `file:line` findings, a diff, or a short summary.
- Run read-only agents in parallel. Run agents that write the same files one at a time.
- Verify output (build, tests, lint) before accepting it.

Model choice:

- A main session on Fable plans first: subtasks, model and effort for each, dependencies. It does the hardest, most coupled piece itself and delegates the rest per the table, at medium effort, high only for plans the whole task depends on.
- When a major refactor, migration, architecture task or long unattended run starts, suggest Fable. Mid-session, use a Fable subagent instead, or suggest `/compact` or a plan for a fresh session if a switch is still needed.
- When a Fable session has only routine work left, suggest opus.
- If the advisor is on, consult it before committing to an architecture, after an error recurs twice, and before declaring a multi-step task done.

## Environment safety

- Never kill a process found by matching a name, path or pattern (`pkill -f`, `pgrep | xargs kill`, `killall`). Your own agent and my other dev servers match too. Kill only a PID you captured when you started it, or the owner of your port after you confirm its working directory is yours.
- Never wait with `sleep` or polling loops (`until`, `while`). For a PR, use `watch_pull_request` in T3 Code. For a background command, use `t3_background_wait` or the Monitor tool.
- Stop every server and background process you started before you finish.
- Never write to `~/.t3/userdata`, open its databases read-write, or start a server against it. Reading it read-only is fine.
- Never deploy, change cluster resources, or write to a database outside this machine unless I asked for it in this session. Reading logs, status and data is fine.

## Changes and verification

- Every changed line traces to the request. Report unrelated bugs, dead code and cleanups instead of fixing them. Remove only what your own change made unused.
- Write the least code that solves the request. Keep validation at trust boundaries, error handling that prevents data loss, and security checks.
- Before you add state such as a config key, column, env var, endpoint or abstraction, search the framework, its dependencies and this repo for something that already models it.
- A feature usually has several entry points, for example setup inside a flow and a settings page later. List them, build what was asked, and name the ones you left out.
- Treat a bug report as a symptom. Reproduce it and follow logs, status codes and traces to the failing layer before you change code.
- When a change produces something a machine runs, such as a command, API call, query, workflow or config, check flag names, parameters and argument order against the primary source: `--help`, the schema, the action's `action.yml` or the function's source.
- A green build proves syntax. For anything that calls an external system, run it once against the real target before you call it done. A caveat about your own work, such as "not tested against the real API", is an unfinished task, not a footnote.
- Run the checks CI runs for the files you touched. Leave the full suite to CI unless I ask.

## Tests

- Test behavior that can break: business rules, permission checks, persistence and migrations, parsing of external formats, state transitions, race fixes, and the logic a bug fix changed. Skip what types already guarantee, trivial logic and copy text.
- Test at the lowest layer that fails on the current code. Do not repeat the case in wrappers or at each call site.
- Extend an existing test or table before you add a new test.
- A logic bug fix starts with a test that fails without the fix.
- No sleeps, wall-clock deltas, polling loops, per-test timeouts or retries in tests. Await the event, promise or state that marks the milestone.

## Docs

- Docs state the current truth. No change history, dates, "was previously" or rejected-option debate. Keep the reason for the chosen decision.
- When a decision changes, rewrite or remove the old text. Do not append a second account of it.
- Each decision has one home doc. Other docs point to it and never paraphrase it.
- Do not document what the code already shows: field lists, control flow, file catalogs or PR summaries.
- Do not commit plans, research notes or scratch files unless I ask. Keep them in the scratchpad or temp directory.
- For Amedia repos, the ADRs in `amedia/adr` (via Edda) win over local docs. Surface any conflict.

## Git and pull requests

- Commit, push or open a PR only when I ask or a skill I invoked says to. If you are on the default branch, branch first.
- Never merge a PR, enable auto-merge or push to the default branch unless I asked in this session.
- Find the base branch from GitHub (`gh repo view --json defaultBranchRef` or the PR's `baseRefName`). Never assume `main`.
- Bring a branch up to date by merging the base, never by rebasing, unless I ask. The exception is a branch in a `gh stack` stack, which `gh stack` updates by rebasing and force-pushing with a lease.
- No attribution trailers or "generated with" lines in commits or PRs.
- Check PR titles, bodies and comments for secrets and private details before posting.

## Comments

- Inline comments explain only non-obvious why, such as a constraint, a workaround or a rejected alternative. Never restate what the code does. If code needs a what-comment, simplify the code.
- Give every public item a doc comment in the language's standard format, unless it would only restate the name.
- Doc comments state what the signature cannot show: errors, panics, side effects, units, invariants.
- Every suppression or escape hatch states its reason, for example a disabled lint, an unsafe block, or a cast around the type checker.
- No `TODO` or `FIXME` markers. Placeholder stubs are fine during a task, but none may remain when you finish. Report unfinished work to me instead.
- No comments about the change itself ("added", "fixed", "now uses") or about our conversation. Put that in the commit message.
- When changing code, update its comments. Fix rule-breaking comments only on lines you are already changing.
- No decorative boxes, alignment, or phase markers in tests.

## Writing

Load the `unslop` skill before writing or editing prose: docs, READMEs, ADRs, comments, commit messages, PR text and issues. In every reply, and everywhere else:

- No em dashes. Do not substitute en dashes, hyphens or parentheses. End the sentence or use a comma.
- Use plain words. No AI vocabulary such as "delve", "crucial", "pivotal", "showcase", "leverage".
- Cut filler and hedging: "to" not "in order to", "may" not "could potentially".
- No bold labels that restate the line, and no trailing "-ing" phrases ("ensuring...", "highlighting...").
- Write whole sentences with articles and verbs. No arrows, symbol shorthand or abbreviations the reader must decode.
- Be concrete. Name the mechanism or the number. End on a specific fact or plan.

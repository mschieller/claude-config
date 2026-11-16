# audit

Brings a repo's dependencies and platform metadata up to date in one run, and stops at a summary. You pick the PR shape after reading it.

[SKILL.md](SKILL.md) holds the instructions Claude follows. [PNPM.md](PNPM.md) and [NPM.md](NPM.md) hold the commands for each package manager.

## When to use it

You say "audit", "audit the repo" or "fix the vulnerable dependencies".

For a security review of code, use the built-in `security-review` skill or the [security-reviewer](../../agents/security-reviewer.md) agent.

## What the run does

- Fixes what `pnpm audit` or `npm audit` reports with patch and minor updates, or with a scoped override when no update inside the current major removes the advisory.
- Lists the open Dependabot alerts it did not close.
- Takes a dependency major only when an advisory needs it. The run commits a major on its own when it passes the repo's scripts with no source edit. Any other major is your decision.
- Removes overrides nothing needs any more.
- Writes dependency versions exact. Peer dependencies and the dependencies of a published package keep their ranges.
- Moves Node to the newest release of the active LTS line.
- Moves GitHub Actions to their newest release, pinned to a commit SHA.
- Adds a `CODEOWNERS` file when the repo has none and you agree.
- In an Amedia repo, fixes the problems `apptool who info` lists in whoami and sets up Renovate in place of Dependabot.

It always runs the whole job. With a package manager other than pnpm or npm, it skips the dependency steps and says so. Outside an Amedia repo, it skips whoami and Renovate.

## How to call it

`/audit`, with no arguments.

The run asks you something at three points:

1. After the survey, everything the survey raised in one round. The survey creates the branch, installs and runs the repo's scripts, and changes no tracked file.
2. Before any major upgrade that is not free, one question per major, each with a brief of what breaks.
3. After the summary, whether to ship a single PR or a stack.

Between those points it works unattended. It takes its recommended option for anything new and lists each such choice in the summary.

## What it changes

- On the default branch it creates `chore/audit` first.
- It commits locally, one commit per unit of work, so a stack can be cut at commit boundaries.
- It never pushes the audited repo or opens a PR in it before you have picked the PR shape.
- It opens one PR on its own, and only for an Amedia repo that the Renovate bot's list lacks. That PR goes to `amedia/renovate` and adds the repo to the list. When an open PR there already adds it, the run opens none.
- A fix found in the final verification goes into the commit that caused it, with a fixup and an autosquash rebase. The branch exists only locally at that point.
- When the repo has a `.changeset` folder, it adds a changeset to each commit that changes what a released package ships.

## What it needs

- `gh`, logged in, and `jq`.
- pnpm or npm, at the version the repo pins.
- In an Amedia repo, `apptool`.
- The run uses Docker and `actionlint` when they are installed.

## Related skills

[ship](../ship/README.md) takes over after you pick the PR shape. For a stack, `audit` gives it the layer plan.

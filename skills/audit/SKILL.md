---
name: audit
description: Bring a repo's dependencies and platform metadata up to date in one run. Fixes what `pnpm audit` or `npm audit` reports, updates outdated packages, pins every version, moves Node to the active LTS, fixes the problems `apptool who info` lists in whoami, and sets up Renovate in place of Dependabot. Surveys first, asks its questions in one round, works unattended, then reports and recommends a single PR or a stack. Always runs the whole job. Use when the user says "audit", "audit the repo" or "fix the vulnerabilities". For a security review of code, use security-review.
argument-hint: "[whoami owner id, default okt-bruk-presentasjonsplattform]"
---

# Audit

Do the whole job in one run and stop at the summary. The user picks the PR shape after reading it.

## Rules

- Commit locally, one commit per unit, in the order of the steps below. A stack can then be cut at commit boundaries.
- Never push the audited repo or open a PR in it before the user has picked the PR shape. The one PR this skill opens on its own is the one against `amedia/renovate` in step 4.
- Steps 3 and 4 run only in an Amedia repo, one whose `origin` remote is in the `amedia` GitHub org. In any other repo, skip them and say so in the summary.
- The reference file for the package manager holds the commands. The repo pins its own package manager version, so check a command against its `--help` in the repo when it fails or behaves differently.
- A dependency version is always written exact, as `1.2.3`. No `^`, no `~`, no range. `peerDependencies` are the exception and keep their ranges.

## 1. Survey

Change nothing in this step.

- Run `git status --short`. If the tree has uncommitted changes, add that to the questions in step 2. If the current branch is the default branch, create `chore/audit` from it.
- Find the package manager from the `packageManager` field and the lockfile. Read [PNPM.md](PNPM.md) for `pnpm-lock.yaml` and [NPM.md](NPM.md) for `package-lock.json`. With any other package manager, or none, skip steps 5, 7 and 8 and say so in the summary.
- List every `package.json` in the repo and whether the repo is a workspace.
- Run the frozen install.
- Record the audit counts for info, low, moderate, high and critical. These are the "before" numbers in the summary.
- Record the outdated packages, split into those with a newer patch or minor and those with a newer major.
- Find every place that sets a Node version: `engines.node`, `.node-version`, `.nvmrc`, `.tool-versions`, `volta`, `node-version` inputs in workflows, every `FROM` in a Dockerfile, `@types/node` and a `@tsconfig/node<major>` base.
- Find the active LTS line of Node. In `https://raw.githubusercontent.com/nodejs/Release/main/schedule.json` it is the line whose `lts` date has passed and whose `maintenance` date has not. Its newest release is the first entry in `https://nodejs.org/dist/index.json` whose `lts` field holds that line's codename.
- In an Amedia repo, run `apptool who info` and read the validation problems from its plain output. The `--json` output leaves them out. Find every whoami file with the glob `**/whoami*.yaml`.
- In an Amedia repo, record four facts about Renovate:
  - whether a Renovate config exists: `renovate.json`, `renovate.json5` or `.renovaterc`, at the root or under `.github/`
  - whether a Dependabot config exists, and which workflows mention `dependabot`
  - whether `config/renovate-config.js` in `amedia/renovate` lists the repo
  - whether the bot has an open onboarding PR in the repo, titled "configure renovate"
- Run every script in each `package.json` that tests, lints, typechecks or builds. Record what already fails. This is the baseline for step 9.

## 2. Questions

Ask everything the survey raised in one round with AskUserQuestion, with the recommended option first. Ask nothing the survey can answer. Typical questions:

- A whoami problem with more than one valid fix. For an unknown system, offer the ids from `apptool who systems`. For a redundant channel whose value differs from the owner's, offer to remove it and use the owner's channel, or to keep it and leave the problem reported. For a key that appears twice with different values, offer each value.
- A whoami owner that is neither the owner id from the arguments nor one of its aliases in `apptool who owners <id>`. The repo may belong to another team.
- The section of `config/renovate-config.js` the repo belongs under, when the owner from the arguments is not the default. Offer the section comments in that file.
- Tests that fail before any change. Offer to continue with those failures noted, or to stop.
- Uncommitted changes in the tree.

After this round the run is unattended. When something new comes up, take the option you would have recommended and list it in the summary.

## 3. Whoami

- Set `owner` to the id from the arguments, or to `okt-bruk-presentasjonsplattform` when none is given.
- Fix each validation problem from the survey. An owner alias becomes the owner id.
- thewho calls a channel redundant when the whoami file sets a channel type that the owner's record in `apptool who owners <id>` also has, whatever the values are. Remove the key when its value equals the owner's. When the value differs, removing it moves those notifications to the owner's channel, so that is a question for step 2.
- When a key appears twice with the same value, keep one. When the values differ, that is a question for step 2.
- thewho reads the default branch, so `apptool who info` shows the old problems until the change is merged. Check the edit instead: the file parses as YAML, no key appears twice, the owner exists in `apptool who owners` and the system exists in `apptool who systems`. A GitHub check validates the schema on the PR.
- Commit.

## 4. Renovate

Amedia runs one Renovate bot from `amedia/renovate`. It only processes the repos listed in `config/renovate-config.js`.

- If the repo has no Renovate config, write `.github/renovate.json5`:

  ```json5
  {
    "$schema": "https://docs.renovatebot.com/renovate-schema.json",
    "extends": ["github>amedia/renovate", ":pinAllExceptPeerDependencies"]
  }
  ```

- If it has one, check that it extends `github>amedia/renovate` or presets from that repo, and that it has `:pinAllExceptPeerDependencies`. The shared preset pins only dev dependencies. Add what is missing and keep the rest.
- Delete the Dependabot config, and delete the workflows and steps that only act for `dependabot[bot]`. Leave Dependabot alerts on. They are a repo setting, not a file.
- Commit, then dry-run from the repo root. Renovate ignores an untracked config file.

  ```
  GITHUB_COM_TOKEN=$(gh auth token) LOG_LEVEL=debug npx --yes renovate --platform=local > <scratchpad>/renovate.log 2>&1
  ```

  The run is good when the log says `Config file exists` for the config, has no line about an onboarding branch, and ends `Dependency extraction complete` with counts that cover the package files, the Dockerfiles and the workflows. Collect every `Failed to look up` line for the summary. A private package fails here because the local run has no registry login. The local run only looks up versions. It does not simulate branches or PRs.
- If `config/renovate-config.js` does not list the repo, open a PR that adds it. Clone `amedia/renovate` into the scratchpad, branch, add `"amedia/<repo>",` as the last line of the block under the section comment, `// Presentasjonsplattform` unless step 2 chose another, and follow that repo's commit and PR title convention. Open one PR per audited repo. In T3 Code, link the PR to the thread. Do not watch or merge it.
- Leave an open onboarding PR from the bot alone and name it in the summary. The config from this run replaces it.

## 5. Pin and settings

- Apply the settings from the reference file.
- Write every entry in `dependencies`, `devDependencies` and `optionalDependencies` as the exact version the lockfile resolves today. Do not strip the `^` or `~` from the range. That gives the lowest version the range allows, which can be older than the installed one.
- Leave `peerDependencies` and entries that are not registry versions as they are: `workspace:`, `catalog:`, `file:`, `link:`, git and URL entries.
- Update the lockfile without installing. Its resolved versions must not change in this commit.
- Commit.

## 6. Node

- The target is the newest release of the active LTS line from the survey.
- Update every place from the survey and keep the form each place already uses, such as `26`, `>=26` or `26.13.1`. Amedia's CI installs the version in `engines.node` and fails or warns when the major in the Dockerfile's final `FROM` differs.
- In a Dockerfile, keep the registry and the image variant and change only the version. Confirm that the tag exists in its registry before you write it.
- Set `@types/node` to the newest version with the same major as Node.
- Commit.

## 7. Updates and fixes

Work in this order and stop as soon as the audit is clean and nothing is outdated within its major.

1. Run the audit fix that updates the lockfile.
2. Move each direct dependency to the newest patch or minor of its current major.
3. For each advisory that is left, find which direct dependency pulls the package in, and update that dependency.
4. Add an override only when no update removes the advisory. Record the package, the version and the advisory id for the summary.
5. Remove existing overrides that no advisory needs any more. Check by removing one and running the audit again.

Commit when done.

## 8. Majors

Attempt a major upgrade only when an advisory cannot be fixed without it. For every other package with a newer major, write one line for the summary with what the major changes for this repo, and leave it for Renovate.

For each major an advisory needs:

- Take the version the registry tags `latest`. Skip it when it has a prerelease suffix such as `-rc`, `-beta` or `-alpha`.
- Read the changelog or migration guide from the current version to that one. Search the repo for each API it removes or changes.
- When nothing the repo uses breaks, or the needed changes are small and clear, upgrade and run the tests. Commit each major on its own.
- When the tests fail and the fix is not small, or you are not confident, undo the upgrade and record the package, the target version and the reason.

## 9. Verify

- Run every script from the survey's baseline again. A script that passed before must pass now.
- When a Dockerfile changed and Docker is available, build the image.
- Trace each new failure to its commit. Fix it there, or revert that commit and record why.
- Record the audit counts again. These are the "after" numbers.

## 10. Summary

Report in this order:

- The audit counts before and after, as a table with info, low, moderate, high and critical.
- Each advisory that is left, with the reason it could not be fixed.
- Each updated package as `{name}: {old} -> {new}`, under `dependencies` and `devDependencies`.
- Node: the version before and after, and each file that changed.
- Whoami: what changed, and any problem left. Say that `apptool who info` shows the result only after the merge.
- Renovate: added, updated or already correct. The dry-run result and the failed lookups. The URL of the `amedia/renovate` PR, and that it should merge after the repo's own PR, because the bot opens an onboarding PR in a listed repo that has no config. Any open onboarding PR.
- Majors: each one done, and each one not done with its reason.
- Overrides added and removed.
- What the user must test by hand because this run could not.
- Each choice made without asking.
- The PR shape recommendation from step 11.

## 11. PR shape

Count the change with `git diff --numstat <merge-base> HEAD`, leaving out lockfiles.

Recommend a single PR when no major upgrade needed source changes and the count is under about 300 changed lines. Otherwise recommend a stack, cut at commit boundaries in this order, bottom first:

1. whoami and Renovate
2. pin and settings
3. Node
4. updates and fixes
5. one layer per major that changed source code

Fold a small layer into its neighbour. Say how many layers the stack has and why each one is separate.

Ask with AskUserQuestion, with the recommended shape first. Then hand over to the `ship` skill. For a stack, give it the layer plan: for each layer, bottom to top, the branch name, its last commit, the PR title and what the body should say.

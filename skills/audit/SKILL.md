---
name: audit
description: Bring a repo's dependencies and platform metadata up to date in one run. Fixes what `pnpm audit` or `npm audit` reports, updates outdated packages, removes overrides nothing needs any more, pins every version, moves Node to the active LTS, moves GitHub Actions to their newest release pinned to a commit SHA, fixes the problems `apptool who info` lists in whoami, and sets up Renovate in place of Dependabot. Surveys first, asks its questions in one round, works unattended, then reports and recommends a single PR or a stack. Always runs the whole job. Use when the user says "audit", "audit the repo" or "fix the vulnerabilities". For a security review of code, use security-review.
---

# Audit

Do the whole job in one run and stop at the summary. The user picks the PR shape after reading it.

## Rules

- Commit locally, one commit per unit, in the order of the steps below. A stack can then be cut at commit boundaries.
- Never push the audited repo or open a PR in it before the user has picked the PR shape. The one PR this skill opens on its own is the one against `amedia/renovate` in step 5.
- Steps 3 and 5 run only in an Amedia repo, one whose `origin` remote is in the `amedia` GitHub org. In any other repo, skip them and say so in the summary.
- The reference file for the package manager holds the commands. The repo pins its own package manager version, so check a command against its `--help` in the repo when it fails or behaves differently.
- A dependency version is always written exact, as `1.2.3`. No `^`, no `~`, no range. `peerDependencies` are the exception and keep their ranges.

## 1. Survey

Change nothing in this step.

- Run `git status --short`. If the tree has uncommitted changes, add that to the questions in step 2. If the current branch is the default branch, create `chore/audit` from it.
- Find the package manager from the `packageManager` field and the lockfile. Read [PNPM.md](PNPM.md) for `pnpm-lock.yaml` and [NPM.md](NPM.md) for `package-lock.json`. With any other package manager, or none, skip steps 6, 9 and 10 and say so in the summary.
- List every `package.json` in the repo and whether the repo is a workspace.
- Run the frozen install.
- Record the audit counts for info, low, moderate, high and critical. These are the "before" numbers in the summary.
- Record the outdated packages, split into those with a newer patch or minor and those with a newer major.
- List every override in the places the reference file names. Find why each one was added, from a comment next to it or from the commit that added it and that commit's PR. `git log -S'<name>' --reverse -- <file>` lists the commits that changed the name, oldest first. Record the reason as a fix, when the forced version fixes an advisory or a bug, or as a hold-back, when a newer version broke the repo. Record it as unknown when nothing says.
- Find every place that sets a Node version: `engines.node`, `.node-version`, `.nvmrc`, `.tool-versions`, `volta`, `node-version` inputs in workflows, every `FROM` in a Dockerfile, `@types/node` and a `@tsconfig/node<major>` base.
- Find the active LTS line of Node. In `https://raw.githubusercontent.com/nodejs/Release/main/schedule.json` it is the line whose `lts` date has passed and whose `maintenance` date has not. Its newest release is the first entry in `https://nodejs.org/dist/index.json` whose `lts` field holds that line's codename.
- In an Amedia repo, run `apptool who info` and read the validation problems from its plain output. The `--json` output leaves them out. Find every whoami file with the glob `**/whoami*.yaml`, and compare the `owner` in each with the owner ids in `apptool who owners --json`.
- Look for a `CODEOWNERS` file in `.github/`, at the root and in `docs/`, the three places GitHub reads. When there is none, collect candidates for the question in step 2: the user's own login from `gh api user`, and in an org repo the user's teams from `gh api user/teams`, filtered to that org and to the teams that pass the access check in step 4.
- In an Amedia repo, record four facts about Renovate:
  - whether a Renovate config exists: `renovate.json`, `renovate.json5` or `.renovaterc`, at the root or under `.github/`
  - whether a Dependabot config exists, and which workflows mention `dependabot`
  - whether `config/renovate-config.js` in `amedia/renovate` lists the repo
  - whether the bot has an open onboarding PR in the repo, titled "configure renovate"
- Run every script in each `package.json` that tests, lints, typechecks or builds. Record what already fails. This is the baseline for step 11.

## 2. Questions

Ask everything the survey raised in one round with AskUserQuestion, with the recommended option first. A round may take several dialogs, since one dialog holds four questions. Ask nothing the survey can answer. Ask about the whoami owner first, because the channel and section questions depend on who the owner is. Typical questions:

- A whoami problem with more than one valid fix. For an unknown system, offer the ids from `apptool who systems`. For a redundant channel whose value differs from the owner's, offer to remove it and use the owner's channel, or to keep it and leave the problem reported. For a key that appears twice with different values, offer each value.
- A whoami owner that is not the `id` of any owner in `apptool who owners --json`. Offer the closest owner ids, and recommend the one whose `aliases` or `name` hold the current value or resemble it. Recommend none when nothing resembles it.
- The section of `config/renovate-config.js` the repo belongs under, when no section comment in that file appears in the owner's `id`, `name` or `aliases`, ignoring case. Offer the section comments.
- A missing `CODEOWNERS` file. Ask whether to add one. If yes, ask who owns the code: one owner for everything, or different owners for different paths, and which teams or people. Offer the candidates from the survey and let the user name others. Recommend one team for `*` when the user is in a team with access to the repo.
- An override with an unknown reason. Offer to treat it as a fix, which step 9 removes when nothing needs it, or as a hold-back, which step 9 keeps. Recommend a fix. The baseline scripts in step 9 catch many wrong removals, while a wrongly kept override stays until someone checks it by hand.
- Tests that fail before any change. Offer to continue with those failures noted, or to stop.
- Uncommitted changes in the tree.

After this round the run is unattended. When something new comes up, take the option you would have recommended and list it in the summary.

## 3. Whoami

- Keep an `owner` that is the `id` of an owner in `apptool who owners --json`. Otherwise set it to the id chosen in step 2.
- Fix each validation problem from the survey.
- thewho calls a channel redundant when the whoami file sets a channel type that the owner's record in `apptool who owners <id>` also has, whatever the values are. Remove the key when its value equals the owner's. When the value differs, removing it moves those notifications to the owner's channel, so that is a question for step 2.
- When a key appears twice with the same value, keep one. When the values differ, that is a question for step 2.
- thewho reads the default branch, so `apptool who info` shows the old problems until the change is merged. Check the edit instead: the file parses as YAML, no key appears twice, the owner exists in `apptool who owners` and the system exists in `apptool who systems`. A GitHub check validates the schema on the PR.
- Commit.

## 4. Code owners

Skip this step when the repo has a `CODEOWNERS` file or the user declined one in step 2.

- Write `.github/CODEOWNERS` in the form the user chose. A team is `@<org>/<team-slug>` and a person is `@<login>`. One owner for everything is a single line:

  ```
  * @<org>/<team-slug>
  ```

- With several owners, write one line per path. The last line that matches a file decides its owners, so put `*` first and the narrower paths after it.
- GitHub ignores an owner that has no write access to the repo. Check each one before you write it. `gh api orgs/<org>/teams/<team-slug>/repos/<org>/<repo>` answers 404 for a team without access. `gh api repos/<org>/<repo>/collaborators/<login>/permission` gives a person's permission. Report an owner that fails the check and leave it out.
- GitHub validates the file only on a pushed branch. Put the command for that check in the summary: `gh api "repos/<org>/<repo>/codeowners/errors?ref=<branch>"`.
- Commit.

## 5. Renovate

Amedia runs one Renovate bot from `amedia/renovate`. It only processes the repos listed in `config/renovate-config.js`.

- If the repo has no Renovate config, write `.github/renovate.json5`:

  ```json5
  {
    "$schema": "https://docs.renovatebot.com/renovate-schema.json",
    "extends": [
      "github>amedia/renovate",
      ":pinAllExceptPeerDependencies",
      "helpers:pinGitHubActionDigests"
    ],
    "packageRules": [
      {
        "description": "In-house actions run at @master or a tag, and amedia-actions fork tags never move",
        "matchDepTypes": ["action", "workflow"],
        "matchPackageNames": ["amedia/**", "amedia-actions/**"],
        "pinDigests": false
      }
    ]
  }
  ```

  `helpers:pinGitHubActionDigests` keeps the SHA pins from step 8 current. Without the package rule it also pins `@master` to a SHA, and fixes in `amedia/github-workflows` stop reaching the repo.

- If it has one, check that it extends `github>amedia/renovate` or presets from that repo, and that it has `:pinAllExceptPeerDependencies`, `helpers:pinGitHubActionDigests` and the package rule above. The shared preset pins only dev dependencies and no action digests. Add what is missing and keep the rest.
- Delete the Dependabot config, and delete the workflows and steps that only act for `dependabot[bot]`. Leave Dependabot alerts on. They are a repo setting, not a file.
- Commit, then dry-run from the repo root. Renovate ignores an untracked config file.

  ```
  GITHUB_COM_TOKEN=$(gh auth token) LOG_LEVEL=debug npx --yes renovate --platform=local > <scratchpad>/renovate.log 2>&1
  ```

  The run is good when the log says `Config file exists` for the config, has no line about an onboarding branch, and ends `Dependency extraction complete` with counts that cover the package files, the Dockerfiles and the workflows. No update for an `amedia/` or `amedia-actions/` dependency in the log may have a `newDigest`. Collect every `Failed to look up` line for the summary. A private package fails here because the local run has no registry login. The local run only looks up versions. It does not simulate branches or PRs.
- If `config/renovate-config.js` does not list the repo, open a PR that adds it. Clone `amedia/renovate` into the scratchpad, branch, add `"amedia/<repo>",` as the last line of the block under the section comment that matches the owner, or the one chosen in step 2, and follow that repo's commit and PR title convention. Run `node --check config/renovate-config.js` before you push, because that repo's CI does. Open one PR per audited repo. In T3 Code, link the PR to the thread. Do not watch or merge it.
- Leave an open onboarding PR from the bot alone and name it in the summary. The config from this run replaces it.
- The shared preset takes the reviewers of Renovate's PRs from `CODEOWNERS`. When the repo has no such file after step 4, say in the summary that Renovate's PRs get no reviewers.

## 6. Pin and settings

- Apply the settings from the reference file.
- Write every entry in `dependencies`, `devDependencies` and `optionalDependencies` as the exact version the lockfile resolves today. Do not strip the `^` or `~` from the range. That gives the lowest version the range allows, which can be older than the installed one.
- Leave `peerDependencies` and entries that are not registry versions as they are: `workspace:`, `catalog:`, `file:`, `link:`, git and URL entries.
- Update the lockfile without installing. Its resolved versions must not change in this commit.
- Commit.

## 7. Node

- The target is the newest release of the active LTS line from the survey.
- Update every place from the survey and keep the form each place already uses, such as `26`, `>=26` or `26.13.1`. Amedia's CI installs the version in `engines.node` and fails or warns when the major in the Dockerfile's final `FROM` differs.
- When the `package.json` next to the lockfile has no `engines.node`, add it with the target as an exact version, such as `26.13.1`. Add it also when a file such as `.node-version` sets the version, because Amedia's `node/setup` action fails without `engines.node`. A package published to a registry, one without `"private": true`, gets `>=<major>` instead, because an exact version makes npm warn every consumer on another release.
- In a Dockerfile, keep the registry and the image variant and change only the version. Confirm that the tag exists in its registry before you write it.
- Set `@types/node` to the newest version with the same major as Node.
- Commit.

## 8. Workflows

This step covers every `uses:` in `.github/workflows/` and in the repo's own `action.yml` and `action.yaml` files. Skip local paths such as `./.github/actions/build` and `docker://` images.

- An `amedia/` reference at a branch, such as `@master`, stays as it is. `amedia/github-workflows` has no versions and is called at `@master`, so its fixes reach every caller.
- An `amedia/` reference at a tag moves to the repo's newest tag and stays a tag. List the tags with `gh api --paginate repos/<owner>/<repo>/tags --jq '.[].name' | sort -V`. Compare only version tags in the same form as the current ref, such as `v1.2.3` or `1.2.3`, and skip prerelease tags.
- A deprecated `amedia/` reference keeps its ref, and is never swapped for its replacement. That changes inputs and behaviour, so it belongs in its own change. List each deprecated reference in the summary, with the replacement from the migration table in the `amedia/github-workflows` README.
- In an Amedia repo, read the allowlist from `organization/main.tf` in `amedia/terraform-github` with `gh api`. It is `patterns_allowed` and the locals it joins, and `actions/*` and `github/*` are always allowed. An entry that names a ref, such as `owner/repo@v2` or `owner/repo@<sha>`, allows that exact ref and no other.
- Sort each remaining reference in an Amedia repo:
  - A fork under `amedia-actions` moves to its newest tag and stays a tag, found the same way as for an `amedia/` tag. fork-sync mirrors a tag only after 14 days and never moves it.
  - A GitHub-owned action, or one a wildcard entry allows, gets pinned as described below.
  - An action whose allowlist entry names a ref keeps that exact ref, because GitHub blocks any other. List it in the summary. Moving it needs a PR to `amedia/terraform-github`, and Renovate keeps opening PRs for it that fail until `ignore.json` in `amedia/renovate` disables it.
  - Any other action is blocked in the org. Leave it, and list it in the summary with the `amedia-actions` fork that replaces it. When none exists, say that the Infrastructure team creates forks, and give how to request one from the actions limitations page on tech.api.no, found through Edda.
- Outside Amedia, every action gets pinned.

To pin an action:

- Take the highest version among the releases at least 3 days old, the same wait as the shared Renovate preset. `gh api --paginate repos/<owner>/<repo>/releases` lists them with `published_at`, but not in version order, since a backport to an old major can come first. Skip drafts and prereleases. When the repo has no releases, take the highest version tag.
- Resolve the tag with `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`. This endpoint follows an annotated tag to its commit.
- Write the reference as `<owner>/<repo>/<path>@<full sha> # <tag>`, keeping the path when the reference has one, such as `/init` in `github/codeql-action/init`, and with the full tag such as `v4.2.1`. Renovate reads the comment as the current version.
When a reference would move to a new major, whether a tag or a pin, read the release notes between the two versions. Compare the inputs the workflow passes and the outputs it reads with `action.yml` or `action.yaml` in the action's path at the new tag, fetched with `gh api -H 'Accept: application/vnd.github.raw' 'repos/<owner>/<repo>/contents/<path>/action.yml?ref=<tag>'`. For a reusable workflow, compare with its `on.workflow_call` block. Take the major when each one still exists with the same meaning. Otherwise take the newest version in the current major and record the major for the summary.

Commit when done.

## 9. Updates and fixes

Work through these in order and stop as soon as the audit is clean and nothing is outdated within its major.

1. Run the audit fix that updates the lockfile.
2. Move each direct dependency to the newest patch or minor of its current major.
3. For each advisory that is left, find which direct dependency pulls the package in, and update that dependency.
4. Add an override only when no update removes the advisory. Record the package, the version and the advisory id for the summary.

Then check each override from the survey, also when the audit was clean from the start. Overrides from item 4 stay.

- Remove an override outside the root `package.json` and the root `pnpm-workspace.yaml`. npm and pnpm ignore it.
- Remove an override for a package that nothing in the tree depends on any more.
- When the audit reports the version an override forces, raise the override to the lowest version that fixes the advisory. Updating the parent cannot fix that.
- Remove each other override, update the lockfile without installing, and compare the versions the package resolves to with and without it. Keep the override when a version drops or the audit reports a new advisory.
- Otherwise remove a fix and keep a hold-back, by the reason from the survey or the answer from step 2. An unchanged version does not show that a hold-back is no longer needed, because the lockfile keeps any version the parent's range allows until the next update.
- Run the baseline scripts after the removals. When one that passed now fails, put the removed overrides back one at a time until it passes, and keep the last one you put back.

Commit when done.

## 10. Majors

Attempt a major upgrade only when an advisory cannot be fixed without it. For every other package with a newer major, write one line for the summary with what the major changes for this repo, and leave it for Renovate.

For each major an advisory needs:

- Take the version the registry tags `latest`. Skip it when it has a prerelease suffix such as `-rc`, `-beta` or `-alpha`.
- Read the changelog or migration guide from the current version to that one. Search the repo for each API it removes or changes.
- When nothing the repo uses breaks, or the needed changes are small and clear, upgrade and run the tests. Commit each major on its own.
- When the tests fail and the fix is not small, or you are not confident, undo the upgrade and record the package, the target version and the reason.

## 11. Verify

- Run every script from the survey's baseline again. A script that passed before must pass now.
- When a Dockerfile changed and Docker is available, build the image.
- When a workflow changed and `actionlint` is installed, run it. When it is not installed, skip it and leave it out of the summary.
- Trace each new failure to its commit. Fix it there, or revert that commit and record why.
- Record the audit counts again. These are the "after" numbers.

## 12. Summary

Report in this order:

- The audit counts before and after, as a table with info, low, moderate, high and critical.
- Each advisory that is left, with the reason it could not be fixed.
- Each updated package as `{name}: {old} -> {new}`, under `dependencies` and `devDependencies`.
- Node: the version before and after, and each file that changed.
- Workflows: each action as `{name}: {old} -> {new}`, and each major not taken with its reason. The actions kept at an allowlisted ref, the blocked actions with their forks, and the deprecated `amedia/github-workflows` references with their replacements. Outside Amedia, say that nothing updates the pins until the repo runs Renovate or Dependabot.
- Whoami: what changed, and any problem left. Say that `apptool who info` shows the result only after the merge.
- Code owners: the file added and its owners, or that the repo already had one, or that the user declined. The command that checks the file after the push.
- Renovate: added, updated or already correct. The dry-run result and the failed lookups. The URL of the `amedia/renovate` PR, and that it should merge after the repo's own PR, because the bot opens an onboarding PR in a listed repo that has no config. Any open onboarding PR.
- Majors: each one done, and each one not done with its reason.
- Overrides added, raised and removed, and each one kept with its reason.
- What the user must test by hand because this run could not.
- Each choice made without asking.
- The PR shape recommendation from step 13.

## 13. PR shape

Count the change with `git diff --numstat <merge-base> HEAD`, leaving out lockfiles.

Recommend a single PR when no major upgrade needed source changes and the count is under about 300 changed lines. Otherwise recommend a stack, cut at commit boundaries in this order, bottom first:

1. whoami, code owners and Renovate
2. pin and settings
3. Node
4. workflows
5. updates and fixes
6. one layer per major that changed source code

Fold a small layer into its neighbour. Say how many layers the stack has and why each one is separate.

Ask with AskUserQuestion, with the recommended shape first. Then hand over to the `ship` skill. For a stack, give it the layer plan: for each layer, bottom to top, the branch name, its last commit, the PR title and what the body should say.

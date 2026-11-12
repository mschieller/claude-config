# pnpm

The commands for the `audit` skill in a repo with `pnpm-lock.yaml`. In a workspace, add `-r` to `outdated`, `ls` and `why`.

## Settings

`pnpm-workspace.yaml` must have both settings. Create the file if the repo has none. Add a setting only when it is missing, because a key that appears twice breaks every pnpm command.

```yaml
saveExact: true
minimumReleaseAge: 1440
```

- `saveExact` makes `pnpm add` write a new dependency without a range.
- `minimumReleaseAge` is in minutes. pnpm refuses a version published less than a day ago. Raise a lower value to 1440. Keep a higher value and report it.
- When the release age blocks a fix, report the package and the version. Leave an existing `minimumReleaseAgeExclude` as it is, and do not add to it to get a fix through.
- pnpm warns about a setting it does not recognize. If it warns about one of these two, the repo's pnpm is too old for it. Report that, and list the pnpm upgrade with the majors.

## Commands

| Task | Command |
|---|---|
| Frozen install | `pnpm install --frozen-lockfile` |
| Audit counts | `pnpm audit --json`, under `metadata.vulnerabilities` |
| Audit fix that updates the lockfile | `pnpm audit --fix update` |
| Outdated packages | `pnpm outdated --format json`, which gives `current`, `wanted` and `latest` |
| Resolved version of each direct dependency | `pnpm ls --json --depth 0` |
| What pulls a package in | `pnpm why <name>` |
| Update the lockfile without installing | `pnpm install --lockfile-only` |

- Bare `pnpm audit --fix` uses the `override` method and writes overrides. Use it only for step 9.4 of the skill.
- `pnpm audit --fix update` rewrites a range to start at the version it installs. In an entry that keeps its range, set the lower bound back to the version that fixes the advisory, as step 9 of the skill says.
- To move a direct dependency, edit its version in `package.json`, or in the catalog when the entry says `catalog:`, and run `pnpm install`. A catalog entry that the Pin section leaves as a range moves like a range in a published package. `pnpm add` and `pnpm update` keep a `^` or `~` that the entry already has, also with `saveExact` or `-E`.
- A `peerDependencies` entry for the same package changes only by the rules in steps 6, 9 and 10 of the skill.
- For an entry that keeps its range, `pnpm update <name> --no-save` moves the lockfile inside the range. Without `--no-save`, `pnpm update` rewrites the range to start at the new version.

## Pin

Take each version from `pnpm ls --json --depth 0` and write it into the entries of `package.json` that step 6 of the skill pins. A `catalog` in `pnpm-workspace.yaml` is pinned the same way. Its resolved versions are under `catalogs:` in `pnpm-lock.yaml`. Leave a catalog entry that a published package uses in `peerDependencies`, `dependencies` or `optionalDependencies`, and report it. pnpm writes the catalog's value into the package it publishes, so an exact version there reaches every consumer. Keep the comments in `pnpm-workspace.yaml`. Run `pnpm install --lockfile-only`. In `git diff pnpm-lock.yaml`, only `specifier:` lines may change.

## Overrides

Overrides are under `overrides` in `pnpm-workspace.yaml`, or under `pnpm.overrides` in `package.json` in repos on an older pnpm. Check both places, and the `package.json` of each workspace package too. pnpm ignores `pnpm.overrides` outside the root without a warning.

`pnpm why <name>` lists each version of the package in the lockfile and what pulls it in.

## Package manager version

`packageManager` in `package.json` names the pnpm version CI installs. Update it to the newest release of its current major. Treat a newer major like any other major in step 10 of the skill.

## Build scripts

Current pnpm runs the build script of a dependency only when the repo allows it. When an install reports a build script it did not run for a dependency this run added or updated, report it. Do not allow it yourself.

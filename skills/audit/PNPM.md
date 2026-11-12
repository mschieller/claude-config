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

- Bare `pnpm audit --fix` uses the `override` method and writes overrides. Use it only for step 7.4 of the skill.
- To move a direct dependency, edit its version in `package.json`, or in the catalog when the entry says `catalog:`, and run `pnpm install`. `pnpm add` and `pnpm update` keep a `^` or `~` that the entry already has, also with `saveExact` or `-E`.

## Pin

Take each version from `pnpm ls --json --depth 0` and write it into `package.json`. A `catalog` in `pnpm-workspace.yaml` is pinned the same way. Its resolved versions are under `catalogs:` in `pnpm-lock.yaml`. Keep the comments in `pnpm-workspace.yaml`. Run `pnpm install --lockfile-only`. In `git diff pnpm-lock.yaml`, only `specifier:` lines may change.

## Overrides

Overrides are under `overrides` in `pnpm-workspace.yaml`, or under `pnpm.overrides` in `package.json` in repos on an older pnpm. Check both places.

## Package manager version

`packageManager` in `package.json` names the pnpm version CI installs. Update it to the newest release of its current major. Treat a newer major like any other major in step 8 of the skill.

## Build scripts

Current pnpm runs the build script of a dependency only when the repo allows it. When an install reports a build script it did not run for a dependency this run added or updated, report it. Do not allow it yourself.

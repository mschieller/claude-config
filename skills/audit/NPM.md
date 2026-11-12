# npm

The commands for the `audit` skill in a repo with `package-lock.json`. In a workspace, add `--workspaces` to `outdated` and `ls`, and `-w <workspace>` to `install <name>@<version>`.

## Settings

`.npmrc` at the repo root must have this line. Create the file if the repo has none.

```ini
save-exact=true
```

It makes `npm install <name>` write the version without a range.

## Commands

| Task | Command |
|---|---|
| Frozen install | `npm ci` |
| Audit counts | `npm audit --json`, under `metadata.vulnerabilities` |
| Audit fix that updates the lockfile | `npm audit fix` |
| Outdated packages | `npm outdated --json`, which gives `wanted` and `latest` |
| Resolved version of each direct dependency | `npm ls --package-lock-only --json --depth=0` |
| What pulls a package in | `npm explain <name>` |
| Move a direct dependency | `npm install <name>@<version>` |
| Update the lockfile without installing | `npm install --package-lock-only` |

- Never run `npm audit fix --force`. It applies major upgrades without the check in step 10 of the skill.
- `npm install <name>@<version>` keeps the dependency in its group.
- If the repo's CI installs with `--ignore-scripts`, pass it to `npm ci` and `npm install` too.

## Pin

Take each version from `npm ls --package-lock-only --json --depth=0` and write it into `package.json`. Run `npm install --package-lock-only`. In `git diff package-lock.json`, only the ranges in the root package entry may change.

## Overrides

Overrides are under `overrides` in `package.json`.

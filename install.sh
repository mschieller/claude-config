#!/usr/bin/env bash
# Links this repo's CLAUDE.md, skills and agents into ~/.claude.
# Skills are linked one directory at a time because ~/.claude/skills/synced is managed by claude.ai.
# An existing file that is not a symlink is left alone and reported, so nothing is overwritten.
# A link into this repo whose target is gone is removed, so a deleted skill or agent does not linger.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
target="$HOME/.claude"

# A linked worktree is temporary. Links into it break when it is removed.
git_dir="$(git -C "$repo" rev-parse --path-format=absolute --git-dir 2>/dev/null || true)"
common_dir="$(git -C "$repo" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
if [ "$git_dir" != "$common_dir" ]; then
  echo "refused: $repo is a linked worktree. Run install.sh from the main checkout." >&2
  exit 1
fi

link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ]; then
    ln -sfn "$src" "$dst"
  elif [ -e "$dst" ]; then
    echo "skipped: $dst exists and is not a symlink" >&2
    return
  else
    ln -s "$src" "$dst"
  fi
  echo "linked: $dst"
}

mkdir -p "$target/skills" "$target/agents"
[ -f "$repo/CLAUDE.md" ] && link "$repo/CLAUDE.md" "$target/CLAUDE.md"
for dir in "$repo"/skills/*/; do
  [ -d "$dir" ] || continue
  link "${dir%/}" "$target/skills/$(basename "$dir")"
done
for file in "$repo"/agents/*.md; do
  [ -f "$file" ] || continue
  link "$file" "$target/agents/$(basename "$file")"
done

prune() {
  local dst
  for dst in "$1"/*; do
    [ -L "$dst" ] && [ ! -e "$dst" ] || continue
    case "$(readlink "$dst")" in
      "$repo"/*)
        rm "$dst"
        echo "removed dead link: $dst"
        ;;
    esac
  done
}
prune "$target/skills"
prune "$target/agents"

#!/usr/bin/env bash
# Links this repo's CLAUDE.md, skills and agents into ~/.claude.
# Skills are linked one directory at a time because ~/.claude/skills/synced is managed by claude.ai.
# An existing file that is not a symlink is left alone and reported, so nothing is overwritten.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
target="$HOME/.claude"

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

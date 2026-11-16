# unslop

Removes AI patterns from prose and keeps the meaning and the intended tone. The rules cover em dashes, AI vocabulary, filler, hedging, bold labels that restate the line, change narration in docs and comments, and text compressed into arrows and fragments.

[SKILL.md](SKILL.md) holds the rules.

## When to use it

- Claude loads it before writing or editing any prose: docs, READMEs, ADRs, code comments, commit messages, PR descriptions, PR comments and issue text. The Writing section of [CLAUDE.md](../../CLAUDE.md) requires that.
- You call it to clean up prose that already exists.

## How to call it

| Call | Result |
|---|---|
| `/unslop docs/setup.md` | Edits the file in place, then reports which rules it hit and how many times |
| `/unslop <pasted text>` | Replies with the rewrite only |

## What it changes

Only the file you name. With pasted text it changes nothing on disk. It leaves code, quoted text, CLI output, proper names and text you asked to keep verbatim as they are.

## Related skills

[ship](../ship/README.md) writes PR bodies with it, and [review](../review/README.md) writes the comments of a PR review with it.

## Credit

Adapted from `unslop` in [cursor/plugins](https://github.com/cursor/plugins/tree/bc697d0a5a163cec979e362b601e36f5616083fd/pstack/skills/unslop), under the MIT license in [LICENSE](LICENSE).

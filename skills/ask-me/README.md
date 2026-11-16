# ask-me

Walks a list that already exists in the conversation, one item at a time. For each item it explains what was found, offers two to four options with a recommended one, asks in a dialog, and applies your answer before the next item.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

- You have a list of review findings, proposals or open points and want to decide each one yourself.
- You say "ask me per finding", "go through your findings", "walk me through them" or "let's go through the list".
- Another skill hands over its decisions. [review](../review/README.md), [deep-review](../deep-review/README.md), [docs-review](../docs-review/README.md) and [architecture](../architecture/README.md) all do.

This skill produces no findings. With no list in the conversation it says so and stops. To settle a plan whose decisions nobody has listed yet, use [grill](../grill/README.md).

## How to call it

| Call | What it walks |
|---|---|
| `/ask-me` | Every item in the list most recently shown |
| `/ask-me 2 5 7` | Those item numbers |
| `/ask-me security` | That section of the list |
| `/ask-me decide` | Every item, with the answers recorded and nothing changed on disk |

Each dialog shows progress, such as "7 of 28". The skill follows a free-text answer as written.

## What it changes

- It edits files to apply each answer and runs the repo's checks for the files it touched.
- It never commits. A skill that hands over its list can add its own rule, as `deep-review` and `docs-review` do with one commit per answer.
- It asks before a check that writes outside this machine.
- With `decide` it changes nothing.
- It withdraws an item that turns out to be wrong when checked against the code, and shows the evidence.

Run on its own, it ends with a table of every item and its outcome.

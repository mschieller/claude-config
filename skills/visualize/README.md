# visualize

Draws how something works, or how a change alters it, as a diagram grounded in the code. A box and an arrow read as verified even when they are a guess. So every node whose code was read in the session carries a `file:line` anchor, and any other node carries the label `ASSUMED` with what would confirm it.

[SKILL.md](SKILL.md) holds the instructions Claude follows.

## When to use it

- You ask to visualize, draw or diagram something, or say "show me how X works".
- You want to see the before and after of a change.

## How to call it

| Call | What it draws |
|---|---|
| `/visualize` | Whatever the conversation is currently about |
| `/visualize how login works` | That topic |

It picks the smallest form that answers the question: a sequence diagram, a flowchart, a state diagram, a before and after, a call tree, a file tree or an entity diagram. One view is normal and two is the most.

## Where the picture appears

- In T3 Code it renders inline as one HTML page that reads at phone width.
- In a terminal it draws text, such as an indented tree or a `diff` of steps.
- For a PR body or a Markdown doc on GitHub it writes a Mermaid fence.

## What it changes

Nothing in the repo unless you ask. It changes no code. In T3 Code it saves the HTML file to the session's scratchpad folder and gives the path.

## Credit

Adapted from `visualize` in [clawnify/greybeard](https://github.com/clawnify/greybeard), under the MIT license in [LICENSE](LICENSE).

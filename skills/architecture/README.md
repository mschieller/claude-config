# architecture

Finds places where a different structure would make the code easier to change, test and navigate. It shows the strongest candidates as a visual report with a before and after diagram for each, then settles and builds the ones you pick.

[SKILL.md](SKILL.md) holds the instructions Claude follows. [VOCABULARY.md](VOCABULARY.md) defines the terms the report uses, such as module, depth and seam.

## When to use it

- You ask how to improve a codebase's architecture, or where to restructure.
- You ask what to do "if we were to do something drastic".

To find bugs in a change, use [review](../review/README.md) or [deep-review](../deep-review/README.md).

## How to call it

| Call | What it scans |
|---|---|
| `/architecture` | The whole repo, weighted toward the files that change most often |
| `/architecture packages/api` | That area or folder |
| `/architecture #123` | What that PR added or changed |
| `/architecture drastic` | The service as a whole: its design, the SDK or client experience, the UX, developer experience, operations and integrations |

The default mode looks for shallow modules to deepen. You can combine `drastic` with an area.

After the report it asks which candidates to explore. For an open interface shape it offers "design it twice", which gets three designs under different constraints and compares them.

## What it changes

- No code changes until you say build. It then implements one candidate at a time, runs the repo's checks and commits each one.
- It saves the report to the session's scratchpad folder, and into the repo only when you ask.
- When you reject a candidate for a reason a later run would need, it offers to record the reason as an ADR in the repo's format.
- It does not push or open a PR.

## What it needs

- T3 Code shows the report inline. Elsewhere the skill opens the saved HTML file.
- An Explore agent maps the scoped area, and "design it twice" starts three Plan agents.
- In an Amedia repo, the `edda:docs` skill for the org ADRs and conventions.

## Related skills

- [ask-me](../ask-me/README.md) settles the open decisions of each picked candidate, in `decide` mode.
- [grill](../grill/README.md) takes over when a candidate has many open decisions.
- [ship](../ship/README.md) takes the built candidate to a PR.

## Credit

Adapted from `improve-codebase-architecture` and `codebase-design` in [mattpocock/skills](https://github.com/mattpocock/skills), under the MIT license in [LICENSE](LICENSE).

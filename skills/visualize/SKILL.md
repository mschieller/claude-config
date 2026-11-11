---
name: visualize
description: Draw how something works, or how a change alters it, as a diagram grounded in the real code with a file:line anchor on every node. Renders inline in T3 Code so it reads on a phone. Use when the user asks to visualize, draw, diagram or "show me how X works", or to see the before and after of a change.
argument-hint: "[what to visualize, empty means the current topic]"
---

<!-- Adapted from clawnify/greybeard visualize (MIT, see LICENSE). Changes: T3 inline delivery, explain-only scope, shorter form list. -->

# Visualize

Show the thing under discussion as a picture. With no argument, draw whatever the conversation is currently about.

A diagram reads as verified even when it is a guess. Prose says "it probably calls..."; a box and an arrow just assert. So every picture is grounded before it is drawn.

## 1. Ground it

- Read the code you are about to draw, in this repo, this session. If the diagram has five nodes, you opened five things.
- Trace the real flow with a concrete input: carry it through every lookup, guard and branch. If the trace dead-ends, the dead end is what you draw.
- Anchor every node to `path/to/file.ts:42`.
- Draw a node you did not open only when it matters to the shape, and label it `ASSUMED` with what would confirm it.
- For a change, draw the current shape from the code as it is today, then the proposed one.

## 2. Pick the view

Pick the altitude first. "Show me this change" is usually about behavior: what now happens differently, for whom, in what order. Draw the before and after of the behavior in the actor's words (the user, the service, the job), with the anchors on each step. Drop to code structure only when the question is about the code itself: where something lives, how it is wired, what a refactor moves.

Then pick the smallest form that answers the question. One view is normal; two is the most.

| Question | Form |
|---|---|
| How a request or event moves through the system | Sequence diagram |
| Which steps and branches a process takes | Flowchart |
| Which states something can be in and what moves it | State diagram |
| What a change alters | Before and after, side by side or as a `diff` of steps |
| How code calls code | Call tree |
| Where things live, or what a refactor moves | File or component tree |
| How data is shaped and related | Entity diagram with the real column and field names |

## 3. Deliver it

In T3 Code, build one self-contained HTML page and show it with `html_preview`, then `html_render`. Follow `html_render`'s rules: T3's theme variables, no page background, fixed pixel heights for diagrams, readable at phone width. Draw with inline SVG or plain HTML boxes, or Mermaid from a pinned CDN version when the layout is graph-shaped. Put the anchors and `ASSUMED` labels on the nodes themselves, not only in the reply. Save the file to the session's scratchpad folder and give the path.

In a terminal, draw text that already is the picture: indented trees, a `diff` of steps, or box-drawing characters for a sequence. A Mermaid fence in a terminal prints its source, so do not use one there.

For a PR body or a Markdown doc on GitHub, use a Mermaid fence, since GitHub renders it.

When running as a subagent, return the text form or a file path to the agent that started you instead of rendering.

Keep the reply short: one or two sentences on what the picture shows and anything marked `ASSUMED`. Do not restate the diagram in prose. Save nothing into the repo unless the user asks.

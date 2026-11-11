---
name: ask-me
description: Walk a list of findings, proposals or open points with the user, one item at a time. Explains each item, offers options with a recommended one, asks with AskUserQuestion, and applies the answer before the next item. Use when the user says "ask me per finding", "go through your findings", "walk me through them" or "let's go through the list", and when another skill hands over its decisions.
argument-hint: "[decide] [item numbers or a section, empty means all]"
---

# Ask me

Settle a list that already exists, one item at a time. The user decides. You explain, recommend, and carry out each answer.

## 1. Collect the list

- The list is the one most recently shown in the conversation: review findings, proposals or open points. Item numbers or a section name in the arguments narrow it. When another skill hands over, the list is that skill's findings.
- `decide` turns off editing. The answers are recorded and nothing changes on disk.
- If the conversation holds no list, say so and stop. This skill does not produce findings.
- Before the first item, say how many items there are, the order you take them in, and whether answers are applied.

## 2. Order

Take the most severe item first, or keep the order of the skill that handed the list over. Put an item after the items it depends on. When an answer changes a later item, restate that item in its new form when you reach it, or drop it and say why.

## 3. Ask

Check an item against the code before you ask about it. If it turns out to be wrong, withdraw it with the evidence and move on.

Before each dialog, write the outline in text:

- what was found, with its `file:line`
- what it causes if left
- the options and the trade-off between them
- the option you recommend, with the reason in one sentence. Say when the preference is weak.

Then ask with AskUserQuestion:

- Two to four options, the recommended one first and marked. When the item proposes a change, one option is "Leave as is".
- The header shows progress, such as "7 of 28".
- The question stands on its own, because the outline may be hidden while the dialog is open: what was found, what it causes, and what is being chosen.

Ask one item per dialog. Put up to four items in one dialog only when each has two options and none depends on another.

## 4. Read the answer

Follow a free-text answer as written. If it sets a direction that leaves a choice open, ask one follow-up before you edit, and stay on the item until it is settled.

Object once, with the file or line as evidence, only when the chosen option breaks correctness, security or loses data. If the user keeps the answer, follow it.

## 5. Act

Skip this step under `decide`.

Apply the answer before the next question, and say in one line what changed. Check the change before you go on when the check is quick or the next item depends on its result: run the repo's checks for the files you touched, and run anything a machine will execute once against the real target. Ask first when that writes outside this machine. A check that takes more than about a minute and that no later item waits for moves to step 6.

Never commit. A skill that hands over its list may add its own rule for what follows each answer, such as a commit.

## 6. Close

Run the checks that were moved here. A failure reopens its item: say what failed and ask again.

Read the changed files together and look for conflicts the edits created between them. Ask about each one the same way.

If another skill handed over the list, return the outcomes to it, and that skill writes the summary. Otherwise call the `advisor` tool if it is available, then finish with a table of every item and its outcome, followed by the choices you made without asking, what was run for real and what was only checked on paper, and the items not walked.

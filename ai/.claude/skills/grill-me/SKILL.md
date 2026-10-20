---
name: grill-me
description: Use when the user wants a plan, decision, design, or idea stress-tested through a relentless interview. Activate when the user says "grill me", "grill this", "grill my plan", "stress-test this idea", "poke holes in this", "interrogate this design", or "challenge my assumptions". Do not use for writing a spec ticket (use /spec) or for reviewing code.
---

# Grill me

Interview the user relentlessly until you both share one understanding of the plan. Map the plan as a design tree: every decision branches into the decisions that hang off it.

## Rounds

Work the tree in rounds. The frontier is every open decision whose prerequisites are settled: the questions you can ask now without guessing at answers you have not heard yet. Ask the whole frontier each round, then wait for the answers before the next round.

A question whose answer depends on another question still open in this round belongs to a later round.

## Asking

Ask every question through AskUserQuestion. Never write a question as plain text.

- One call holds at most 4 questions. If the frontier is larger, ask it in several calls in a row within the same round, most fundamental decisions first.
- Give each question a short `header` chip and 2 to 4 concrete, mutually exclusive options. Do not add an "Other" option; the tool adds one for free-form answers.
- Put your recommended answer first and append "(Recommended)" to its label. Use its `description` to give the reason in one sentence. Picking the first option must accept your recommendation.
- Use the `preview` field when options are concrete artifacts the user should compare side by side: code snippets, config, layouts, diagrams.
- Use `multiSelect: true` only when choices are not mutually exclusive.
- Before each call, write one short line naming the branch of the tree this round covers.

If an answer is "Other" text that defers or rejects all options, treat the decision as still open and reshape it for the next round, or record it as deferred if the user says so.

## Facts versus decisions

Finding facts is your job, never the user's. When a frontier question needs a fact from the environment (files, code, tools, config), dispatch a sub-agent to find it. Do not ask the user for anything you can look up.

Do not block on the lookup. A running exploration is an unsettled prerequisite, so only the questions downstream of it wait. Ask the rest of the frontier now.

Decisions belong to the user. Put each one to them and wait.

## Updating the tree

Each answer reshapes the tree. Settled decisions push the frontier outward and unblock questions that depended on them. Answers can also open new branches. Recompute the frontier after every round.

## Finishing

The session ends when the frontier is empty: every branch visited, nothing silently assumed. Then print a compact summary of every decision and its answer, and ask one final AskUserQuestion: "Shared understanding reached?" with options to confirm or to keep grilling on a named branch.

Do not act on the plan until the user confirms.

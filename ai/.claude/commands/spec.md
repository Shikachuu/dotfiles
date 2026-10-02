---
description: Lightweight pre-plan step. Saves the raw prompt, restates the task, interviews you on open decisions, and writes a ticket to .claude/specs/ for plan mode.
argument-hint: "[prompt | path/to/ticket.md | (empty to list)]"
allowed-tools: Task, AskUserQuestion, EnterPlanMode, Read, Edit, Glob, Grep, Bash(git rev-parse:*), Bash(date:*)
---

You are the spec coordinator. The `spec-writer` subagent drafts the ticket and the decision list. You run the interview and keep the ticket in sync with the answers. **You do not design or implement anything**. Plan mode does that later.

## 1. Route

Argument: `$ARGUMENTS`

Resolve `repo_root` with `git rev-parse --show-toplevel`, falling back to the current directory. `specs_dir` is `<repo_root>/.claude/specs`. Get `date` with `date +%F`.

- **Empty:** list mode. Glob `specs_dir/*.md` and read each frontmatter. Print one table with columns status, created, title, and path. Put open tickets (`draft`, `clarified`) first, then `planned`, then `done`. If there are none, say so and show the usage line. Stop.
- **Path to an existing `.md` file:** resume mode. Read it. If its status is `planned` or `done`, use AskUserQuestion to offer: mark done / reopen clarification / cancel. Then act on the answer. Otherwise call `spec-writer` with `mode: resume` and go to step 3.
- **Anything else:** new mode. Call `spec-writer` with `mode: new`, `prompt` (the argument verbatim, unchanged), `repo_root`, `specs_dir`, and `date`.

Make one Task call with `subagent_type: spec-writer`. Pass **no** `model` parameter. The agent declares its own `model` and `effort` in frontmatter, and a per-invocation `model` would override it.

## 2. Triage

If the agent returns `TRIVIAL: <reason>`, show the reason. Then use AskUserQuestion with two options: "Just do it" (stop here and do the task as a normal request) or "Write a ticket anyway" (call the agent again and tell it that triage is overridden).

## 3. Interview loop

Read the ticket. Show its `## Understanding` in one short paragraph so the user can catch a misread early.

Keep the agent's decision list as your working set. Repeat until nothing is open:

1. **Frontier:** the open decisions whose `depends_on` are all answered. Ask up to 4 of them in a single AskUserQuestion call. Use the agent's `header`, `question`, and `options` as given.
2. **Fold in** each answer with Edit:
   - Under `## Clarifications`, add a `### Session <date>` heading if this session has none yet. Append `- Q: <question> -> A: <answer>`.
   - Update the body sections the answer affects (Scope, Acceptance criteria, Understanding). Delete or correct any assumption the answer contradicts.
   - If the answer is "you decide" or an equivalent Other, take the recommended option and log it as `-> A: <option> (recommended, accepted)`.
   - If the user's Other text defers the question ("later", "plan mode decides"), move it to `## Open questions (deferred to plan)`.
3. **New forks:** if an answer opens a decision the list did not have, add it with the right `depends_on`. Write its options the same way, recommended first.

When no decisions remain, set `status: clarified` and `updated: <date>` in the frontmatter.

## 4. Handoff

Use AskUserQuestion with three options:

- **Plan now:** set `status: planned`, then call EnterPlanMode and design from the ticket path.
- **Park it:** print the ticket path and `/spec <path>` to resume.
- **Revise:** take free-form changes from the user, fold them in as in step 3, then return here.

## Rules

1. Don't draft the ticket yourself. `spec-writer` does. You route, ask, and fold answers in.
2. Never edit the `## Raw prompt` block.
3. Ask every question through AskUserQuestion, never as a question written in plain text.
4. Don't ask what the code or the ticket already answers.
5. Edit only the ticket. `/spec` never touches code.
6. If the agent fails or returns malformed output, report what it returned. Never fake a ticket.

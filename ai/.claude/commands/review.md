---
description: PR-comment-style review. Fans out code-reviewer, test-engineer, comment-auditor, merge-risk, and edge-case-hunter as subagents, then rewrites their findings as short, friendly review comments ready to paste into a PR.
argument-hint: "[path | commit-range | branch | PR] (optional; defaults to current branch vs main)"
allowed-tools: Task, Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(git merge-base:*), Bash(gh pr diff:*), Bash(gh pr view:*)
---

You are the review coordinator. Your job is to scope the change, dispatch five reviewers in parallel, and rewrite their findings as review comments a teammate would paste into a PR. **You do not review the code yourself**. The subagents do that.

`/review` differs from `/verify` in two ways: the output is a flat list of lowercase one-line comments instead of a sectioned verdict, and `comment-auditor` runs in its lenient review mode. Same agents, same scope, same severity merge.

## 1. Establish scope (once)

Argument: `$ARGUMENTS`

- If the argument is non-empty, treat it as the review target: a path, a commit range like `HEAD~3..HEAD`, a branch, or a PR ref. Resolve its diff accordingly. A PR ref needs its head checked out locally; otherwise the subagents cite the local tree and the line numbers are wrong.
- Otherwise default to the current branch vs `main`:
  - `git merge-base main HEAD`, then `git diff main...HEAD` for committed changes,
  - plus `git status` and `git diff HEAD` for the uncommitted working tree.
- Build a concise **scope descriptor**: the list of changed files and the exact commands to reproduce the diff. You will hand the *same* descriptor to all five subagents so they review identical changes.

## 2. Fan out in parallel

Launch **all five** subagents in a **single message with five Task calls** so they run concurrently with isolated context:

- `subagent_type: code-reviewer` with prompt: "Review the following changes under /review and return your standard report. Scope: <scope descriptor>."
- `subagent_type: test-engineer` with prompt: "Assess the testing of the following changes, run the suite, and smoke-test them; return your standard report. Scope: <scope descriptor>."
- `subagent_type: comment-auditor` with prompt: "Audit the comments in the following changes under /review (review mode) and return your standard report. Scope: <scope descriptor>."
- `subagent_type: merge-risk` with prompt: "Assess the merge risk of the following changes and return your standard report. Scope: <scope descriptor>."
- `subagent_type: edge-case-hunter` with prompt: "Trace the edge cases of the following changes and return your standard report. Scope: <scope descriptor>."

Pass **no** `model` parameter on any Task call. Each agent declares its own `model` and `effort` in frontmatter, and a per-invocation `model` would override it.

Each agent owns its output template. Do not redefine those. Pass scope and collect all five reports.

## 3. Merge the findings

Merge severities the same way `/verify` does:

- One combined Critical / Important / Nit list. Map the comment-auditor's categories in: `Correctness` -> Critical, `MUST KILL` -> Important, `Nit` -> Nit. Carry the edge-case-hunter's Deletions in at the severity each one states, cited at its pre-change `file:line`.
- When several agents flag the same `file:line` or issue, merge into one finding. Keep the higher severity. Never downgrade.
- From merge-risk, carry every Critical and Important gap (`pr:` when it has no line). Among its Nits, keep only gaps that map to a concrete ask: missing proof (screenshot, recording, profile), a one-way door, a swallowed error. Drop the rating and the five category verdicts.
- From edge-case-hunter, drop Declined to judge. Turn Handled but untested items into test-file comments and drop any that duplicate a test-engineer coverage gap. Its no-tests or not-code note goes into the `tests:` line.
- From test-engineer, turn coverage gaps into comments on the test file. When no test file exists, cite the source file or `pr:`. Keep the Smoke Test Result for the `tests:` line. A failing suite is an Important `pr:` finding on top of the `tests:` line.
- Drop every other specialist section: Verification Story, Kept, Skipped, Merge Risk block.

## 4. Write the comments

Rewrite every merged finding as one line:

```
path/file.ext 42: {what is off}, can we {resolution}?
```

- Path is repo-relative and keeps its case. Line is the number alone, no `L` or `:` prefix. A deletion finding cites the old side as `path/file.ext (old) 42:`.
- A finding with no line uses the file alone (`path/file.ext: ...`). A finding about the whole change uses `pr: ...`.
- Order: Critical, then Important, then Nits. Prefix nits with `nit:` before the path (`nit: path/file.ext 7: ...`). No severity label on the others.
- First line is a summary. Pick one: `lgtm` (no findings), `lgtm w/ nits` (nits only), `couple of things before merge` (Important present), `few blockers, see below` (Critical present), `partial review, {agent} did not run` (an agent failed or returned nothing). Add one short clause of context when it helps, like `couple of things before merge, nothing big`. The severity summary wins; append the partial-review note as a clause when both apply. If any agent returned REQUEST CHANGES but no Critical or Important line survived the merge, something was dropped: go back to step 3, and if nothing turns up, add an Important `pr:` line naming the agent and its verdict.
- Then a `tests:` line from the test-engineer's Smoke Test Result: suite pass or fail with counts, smoke outcome, or `could not run, {reason}`. One line.
- Optional final line `nice:` with one concrete positive from any agent. At most one sentence. Skip it when nothing concrete was reported.
- Blank line between the summary and the comments, and between the comments and the `tests:` line.

### Voice

- all lowercase, including the first letter of a line and after a period. File paths and backticked code identifiers keep their case.
- compact: one clause for the problem, one question for the fix. Aim for under 25 words per line.
- friendly and collaborative: "we", "can we", "could we", "wdyt?", "pls". Never "you should", "this is wrong", or "you forgot".
- abbreviations welcome: w/, w/o, b/c, pls, imo, tbh, wdyt, lgtm, nit, fn, var, cfg, ctx, err, impl, repo, ref. Stay with common dev abbreviations.
- questions are full questions with a verb and a question mark. No fragments like "rename?" or "tests?".
- plain words. No idioms or slang beyond the abbreviations above. The team's first language is not always english.
- ASCII only. No emojis, no em-dashes.
- every comment names a real file and line from the agent reports, or `pr:` when the finding has none. Invent nothing. Never soften a Critical into a nit.

### Example

```
couple of things before merge, nothing big

src/api/users.ts 42: `userId` comes from the request body, so any caller can update any user, can we check it against the session user?
src/api/users.ts 58: the catch swallows the db err and still returns 200, can we rethrow or log + return 500?
src/api/users.test.ts 12: only the happy path is covered, can we add a case for the missing-email branch?
nit: src/utils/date.ts 7: `fmt` is a bit vague, could we rename it to `formatIsoDate`?
nit: src/api/users.ts 30: this block is commented-out code, can we drop it?

tests: suite green (42/42), smoke ok on create + delete
nice: the retry around the s3 upload is tested w/ a real timeout, good catch
```

## Rules

1. Don't review the code yourself. You scope, dispatch, and rewrite.
2. Launch all five subagents in one message so they run in parallel with isolated context.
3. Pass all five reviewers the identical scope descriptor.
4. `/review` is read-only. Never edit code, tests, or comments, and never post to GitHub. The user pastes the lines they want.
5. Severity is never downgraded when rewriting. A Critical stays at the top of the list without a `nit:` prefix.
6. If a subagent couldn't run (e.g. the suite is unrunnable), say so in the `tests:` line or a `pr:` line. Never imply verification that didn't happen.

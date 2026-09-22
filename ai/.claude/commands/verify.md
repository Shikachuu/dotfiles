---
description: Parallel pre-merge verification. Fans out code-reviewer, test-engineer, and comment-auditor as subagents, then synthesizes one unified verdict.
argument-hint: "[path | commit-range | branch | PR] (optional; defaults to current branch vs main)"
allowed-tools: Task, Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(git merge-base:*)
---

You are the verification coordinator. Your job is to scope the change, dispatch three reviewers in parallel, and synthesize their reports into one verdict. **You do not review the code yourself**. The subagents do that.

## 1. Establish scope (once)

Argument: `$ARGUMENTS`

- If the argument is non-empty, treat it as the review target: a path, a commit range like `HEAD~3..HEAD`, a branch, or a PR ref. Resolve its diff accordingly.
- Otherwise default to the current branch vs `main`:
  - `git merge-base main HEAD`, then `git diff main...HEAD` for committed changes,
  - plus `git status` and `git diff HEAD` for the uncommitted working tree.
- Build a concise **scope descriptor**: the list of changed files and the exact commands to reproduce the diff. You will hand the *same* descriptor to all three subagents so they review identical changes.

## 2. Fan out in parallel

Launch **all three** subagents in a **single message with three Task calls** so they run concurrently with isolated context:

- `subagent_type: code-reviewer` with prompt: "Review the following changes and return your standard report. Scope: <scope descriptor>."
- `subagent_type: test-engineer` with prompt: "Assess the testing of the following changes, run the suite, and smoke-test them; return your standard report. Scope: <scope descriptor>."
- `subagent_type: comment-auditor` with prompt: "Audit the comments in the following changes and return your standard report. Scope: <scope descriptor>."

Pass **no** `model` parameter on any Task call. Each agent declares its own `model` and `effort` in frontmatter, and a per-invocation `model` would override it.

Each agent already owns its output template (code-reviewer: five dimensions + Verification Story; test-engineer: five dimensions + Smoke Test Result + Coverage Gaps; comment-auditor: MUST KILL + Correctness + Kept). Do not redefine those. Just pass scope and collect all three reports.

## 3. Synthesize one unified report

After all three return, merge them:

- **Overall verdict:** `REQUEST CHANGES` if *any* agent requests changes; otherwise `APPROVE`. If the only findings across all three are Nits -> `APPROVE`.
- **Merged findings:** one combined Critical / Important / Nit list. Map the comment-auditor's categories in: `Correctness` -> Critical, `MUST KILL` -> Important, `Nit` -> Nit. Attribute each line `[code-reviewer]`, `[test-engineer]`, or `[comment-auditor]`; when several flag the same `file:line`/issue, merge into one line listing every agent that flagged it, or `[all]` when all three did. When merging, keep the higher severity. Never downgrade.
- **Specialist sections:** preserve the test-engineer's Smoke Test Result and Coverage Gaps, the code-reviewer's Verification Story, and the comment-auditor's MUST KILL, Correctness, Kept, and Skipped lists.
- **What's done well:** combine the positives from any subagent that reported one.

## Rules

1. Don't review the code yourself. You scope, dispatch, and synthesize.
2. Launch all three subagents in one message so they run in parallel with isolated context.
3. Pass all three reviewers the identical scope descriptor.
4. `/verify` is read-only. Never modify code, tests, or comments; surface fixes as recommendations. `/no-comments` is where comment findings get applied.
5. On conflicting verdicts, the stricter one wins.
6. If a subagent couldn't run (e.g. the suite is unrunnable), report that honestly in the summary. Never imply verification that didn't happen.

## Output template

```markdown
## Verification Summary

**Verdict:** APPROVE | REQUEST CHANGES
**Scope:** [what was reviewed]
**Overview:** [2-3 sentences combining all three perspectives]

### Critical
- [code-reviewer|test-engineer|comment-auditor|all] [file:line] [issue + recommended fix]

### Important
- [code-reviewer|test-engineer|comment-auditor|all] [file:line] [issue + recommended fix]

### Nits
- [code-reviewer|test-engineer|comment-auditor|all] [file:line] [description]

### Coverage Gaps  (from test-engineer)
- [concrete untested behavior + the test case that should cover it]

### Smoke Test Result  (from test-engineer)
- Commands run / suite pass-fail / manual smoke observations

### Verification Story  (from code-reviewer)
- Tests reviewed / build verified / security checked

### Comment Audit  (from comment-auditor)
- MUST KILL: [file:line + the comment + refactor target, or "none"]
- Correctness: [file:line + the suppression or workaround, or "none"]
- Kept: [file:line + keep-list item, or "none"]
- Skipped: [what the auditor could not read, or "none"]
- Run `/no-comments` to apply these.

### What's Done Well
- [at least one, from any subagent]
```

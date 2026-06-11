---
description: Parallel pre-merge verification — fans out code-reviewer and test-engineer as subagents, then synthesizes one unified verdict.
argument-hint: "[path | commit-range | branch | PR] (optional; defaults to current branch vs main)"
allowed-tools: Task, Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(git merge-base:*)
---

You are the verification coordinator. Your job is to scope the change, dispatch two reviewers in parallel, and synthesize their reports into one verdict. **You do not review the code yourself** — the subagents do that.

## 1. Establish scope (once)

Argument: `$ARGUMENTS`

- If the argument is non-empty, treat it as the review target — a path, a commit range like `HEAD~3..HEAD`, a branch, or a PR ref — and resolve its diff accordingly.
- Otherwise default to the current branch vs `main`:
  - `git merge-base main HEAD`, then `git diff main...HEAD` for committed changes,
  - plus `git status` and `git diff HEAD` for the uncommitted working tree.
- Build a concise **scope descriptor**: the list of changed files and the exact commands to reproduce the diff. You will hand the *same* descriptor to both subagents so they review identical changes.

## 2. Fan out in parallel

Launch **both** subagents in a **single message with two Task calls** so they run concurrently with isolated context:

- `subagent_type: code-reviewer` — "Review the following changes and return your standard report. Scope: <scope descriptor>."
- `subagent_type: test-engineer` — "Assess the testing of the following changes, run the suite, and smoke-test them; return your standard report. Scope: <scope descriptor>."

Each agent already owns its output template (code-reviewer: five dimensions + Verification Story; test-engineer: five dimensions + Smoke Test Result + Coverage Gaps). Do not redefine those — just pass scope and collect both reports.

## 3. Synthesize one unified report

After both return, merge them:

- **Overall verdict:** `REQUEST CHANGES` if *either* agent requests changes; otherwise `APPROVE`. If the only findings across both are Nits → `APPROVE`.
- **Merged findings:** one combined Critical / Important / Nit list. Attribute each line `[code-reviewer]` or `[test-engineer]`; when both flag the same `file:line`/issue, merge into one line tagged `[both]`. When merging, keep the higher severity — never downgrade.
- **Specialist sections:** preserve the test-engineer's Smoke Test Result and Coverage Gaps, and the code-reviewer's Verification Story.
- **What's done well:** combine the positives from both.

## Rules

1. Don't review the code yourself — you scope, dispatch, and synthesize.
2. Launch both subagents in one message so they run in parallel with isolated context.
3. Pass both reviewers the identical scope descriptor.
4. `/verify` is read-only — never modify code or tests; surface fixes as recommendations.
5. On conflicting verdicts, the stricter one wins.
6. If a subagent couldn't run (e.g. the suite is unrunnable), report that honestly in the summary — never imply verification that didn't happen.

## Output template

```markdown
## Verification Summary

**Verdict:** APPROVE | REQUEST CHANGES
**Scope:** [what was reviewed]
**Overview:** [2-3 sentences combining both perspectives]

### Critical
- [code-reviewer|test-engineer|both] [file:line] [issue + recommended fix]

### Important
- [code-reviewer|test-engineer|both] [file:line] [issue + recommended fix]

### Nits
- [code-reviewer|test-engineer|both] [file:line] [description]

### Coverage Gaps  (from test-engineer)
- [concrete untested behavior + the test case that should cover it]

### Smoke Test Result  (from test-engineer)
- Commands run / suite pass-fail / manual smoke observations

### Verification Story  (from code-reviewer)
- Tests reviewed / build verified / security checked

### What's Done Well
- [at least one, from either reviewer]
```

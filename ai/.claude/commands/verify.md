---
description: Parallel pre-merge verification. Fans out code-reviewer, test-engineer, comment-auditor, merge-risk, and edge-case-hunter as subagents, then synthesizes one unified verdict.
argument-hint: "[path | commit-range | branch | PR] (optional; defaults to current branch vs main)"
allowed-tools: Task, Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git log:*), Bash(git merge-base:*)
---

You are the verification coordinator. Your job is to scope the change, dispatch five reviewers in parallel, and synthesize their reports into one verdict. **You do not review the code yourself**. The subagents do that.

## 1. Establish scope (once)

Argument: `$ARGUMENTS`

- If the argument is non-empty, treat it as the review target: a path, a commit range like `HEAD~3..HEAD`, a branch, or a PR ref. Resolve its diff accordingly.
- Otherwise default to the current branch vs `main`:
  - `git merge-base main HEAD`, then `git diff main...HEAD` for committed changes,
  - plus `git status` and `git diff HEAD` for the uncommitted working tree.
- Build a concise **scope descriptor**: the list of changed files and the exact commands to reproduce the diff. You will hand the *same* descriptor to all five subagents so they review identical changes.

## 2. Fan out in parallel

Launch **all five** subagents in a **single message with five Task calls** so they run concurrently with isolated context:

- `subagent_type: code-reviewer` with prompt: "Review the following changes under /verify and return your standard report. Scope: <scope descriptor>."
- `subagent_type: test-engineer` with prompt: "Assess the testing of the following changes, run the suite, and smoke-test them; return your standard report. Scope: <scope descriptor>."
- `subagent_type: comment-auditor` with prompt: "Audit the comments in the following changes and return your standard report. Scope: <scope descriptor>."
- `subagent_type: merge-risk` with prompt: "Assess the merge risk of the following changes and return your standard report. Scope: <scope descriptor>."
- `subagent_type: edge-case-hunter` with prompt: "Trace the edge cases of the following changes and return your standard report. Scope: <scope descriptor>."

Pass **no** `model` parameter on any Task call. Each agent declares its own `model` and `effort` in frontmatter, and a per-invocation `model` would override it.

Each agent already owns its output template (code-reviewer: five dimensions + Verification Story; test-engineer: five dimensions + Smoke Test Result + Coverage Gaps; comment-auditor: MUST KILL + Correctness + Kept; merge-risk: five category verdicts + Merge risk rating; edge-case-hunter: Critical / Important / Nit findings + Deletions + Handled but untested + Declined to judge). Do not redefine those. Just pass scope and collect all five reports.

## 3. Synthesize one unified report

After all five return, merge them:

- **Overall verdict:** `REQUEST CHANGES` if *any* agent requests changes; otherwise `APPROVE`. If the only findings across all five are Nits -> `APPROVE`.
- **Merged findings:** one combined Critical / Important / Nit list. Map the comment-auditor's categories in: `Correctness` -> Critical, `MUST KILL` -> Important, `Nit` -> Nit. merge-risk and edge-case-hunter already report Critical / Important / Nit; carry the edge-case-hunter's Deletions in at the Severity each one states, cited at its pre-change `file:line`. Attribute each line `[code-reviewer]`, `[test-engineer]`, `[comment-auditor]`, `[merge-risk]`, or `[edge-case-hunter]`; when several flag the same `file:line`/issue, merge into one line listing every agent that flagged it, or `[all]` when all five did. When merging, keep the higher severity. Never downgrade.
- **Specialist sections:** preserve the test-engineer's Smoke Test Result and Coverage Gaps, the code-reviewer's Verification Story, the comment-auditor's MUST KILL, Correctness, Kept, and Skipped lists, the merge-risk's rating and five category verdicts, and the edge-case-hunter's Declined to judge list. Append the edge-case-hunter's Handled but untested bullets to Coverage Gaps, attributed `[edge-case-hunter]`, and drop any that duplicate a test-engineer gap. Its one-line note that the scope has no tests or is not code goes under Edge Cases instead.
- **What's done well:** combine the positives from any subagent that reported one.

## Rules

1. Don't review the code yourself. You scope, dispatch, and synthesize.
2. Launch all five subagents in one message so they run in parallel with isolated context.
3. Pass all five reviewers the identical scope descriptor.
4. `/verify` is read-only. Never modify code, tests, or comments; surface fixes as recommendations. `/no-comments` is where comment findings get applied.
5. On conflicting verdicts, the stricter one wins.
6. If a subagent couldn't run (e.g. the suite is unrunnable), report that honestly in the summary. Never imply verification that didn't happen.

## Output template

```markdown
## Verification Summary

**Verdict:** APPROVE | REQUEST CHANGES
**Scope:** [what was reviewed]
**Overview:** [2-3 sentences combining all five perspectives]

### Critical
- [code-reviewer|test-engineer|comment-auditor|merge-risk|edge-case-hunter|all] [file:line] [issue + recommended fix]

### Important
- [code-reviewer|test-engineer|comment-auditor|merge-risk|edge-case-hunter|all] [file:line] [issue + recommended fix]

### Nits
- [code-reviewer|test-engineer|comment-auditor|merge-risk|edge-case-hunter|all] [file:line] [description]

### Coverage Gaps  (from test-engineer and edge-case-hunter)
- [test-engineer|edge-case-hunter] [concrete untested behavior + the test case that should cover it]

### Smoke Test Result  (from test-engineer)
- Commands run / suite pass-fail / manual smoke observations

### Verification Story  (from code-reviewer)
- Tests reviewed / build verified / security checked

### Merge Risk  (from merge-risk)
- Merge risk: low | medium | high
- Alignment / Impact / Verification / Rollback cost / Error detection: [one verdict each]

### Edge Cases  (from edge-case-hunter)
- Declined to judge: [paths set aside, with reasons, or "none"]
- Tests: [the no-tests or not-code note, when the hunter wrote one]

### Comment Audit  (from comment-auditor)
- MUST KILL: [file:line + the comment + refactor target, or "none"]
- Correctness: [file:line + the suppression or workaround, or "none"]
- Kept: [file:line + keep-list item, or "none"]
- Skipped: [what the auditor could not read, or "none"]
- Run `/no-comments` to apply these.

### What's Done Well
- [at least one, from any subagent]
```

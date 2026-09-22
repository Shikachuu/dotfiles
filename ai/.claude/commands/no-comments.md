---
description: Comment cleanup. Spawns comment-auditor on the change, triages its findings, deletes the accepted comments, and fixes what made them necessary.
argument-hint: "[path | commit-range | branch] (optional; defaults to current branch vs main)"
allowed-tools: Task, Read, Edit, Write, Grep, Glob, Bash
---

You spawn `comment-auditor` on a change, triage what it reports, and apply the findings you accept. You do not audit the comments yourself. The subagent does that, and its fresh perspective is the point: an author defends its own comments.

## 1. Establish scope (once)

Argument: `$ARGUMENTS`

- If the argument is non-empty, treat it as the target: a path, a commit range like `HEAD~3..HEAD`, or a branch. Resolve its diff accordingly.
- Otherwise default to the current branch vs `main`:
  - `git merge-base main HEAD`, then `git diff main...HEAD` for committed changes,
  - plus `git status` and `git diff HEAD` for the uncommitted working tree.
- Build a concise **scope descriptor**: the list of changed files and the exact commands to reproduce the diff.

## 2. Spawn the auditor

Launch one Task call with `subagent_type: comment-auditor`, passing the scope descriptor. Do not restate its keep list or its rules; it owns those. Pass no `model` parameter.

## 3. Triage the report

Defer to the auditor's judgment. Reject a finding only when it is wrong on the facts:

- The `file:line` is outside the scope, or the quoted comment is not there.
- A keep-list item covers the comment and you have proof of it, not a plausible story.
- The `MUST KILL` reason misstates what the code does, or the named refactor target is not the guilty symbol.
- The flag treats deliberate, correct code as guilty.

An ambiguous keep is not a keep: when the auditor wanted to delete and you cannot prove the exception, delete. Also audit for what it missed. Scoped lint and TypeScript suppressions it skipped are yours to add as `Correctness` findings if the suppressed rule protects correctness or safety.

If you reject anything, rerun the auditor once with the rejection named. Reject the second report too and you stop: report both failures open and fail `/no-comments` without editing.

## 4. Apply the accepted findings

- Delete every accepted `MUST KILL` and `Nit` comment.
- When a `MUST KILL` names a refactor target, implement the smallest in-scope reshape that makes the comment unnecessary: rename the symbol, extract the branch, tighten the type, delete the dead path. No new abstraction layers. If the fix needs a shape you cannot land in scope, still delete the comment, then describe the shape and report it open.
- For `Correctness`, remove the suppression and fix what it was hiding. If the root cause sits outside the scope, land the smallest in-scope fix and report the rest open. Never bolt on a guard that silences the symptom.
- For constraint comments (`do not remove`, `do not change the wording`, `talk to X first`): if the constraint is genuinely external, it is keep-list item 2 and it stays. Otherwise encode the claim as the cheapest in-scope type, runtime check, test, or lint rule, then delete the comment. Encoding is reversible, so do it without asking. If no in-scope encoding exists, delete the comment anyway and report the constraint open.

## 5. Verify

Format and lint the touched files with the project's configured tools, then run its tests or build. A suite that fails after a deletion means the comment was load-bearing in a way the audit missed: do not restore it, fix the code or report the failure with its output.

## 6. Report

- Comments deleted, by file.
- Findings rejected, and why. Reruns, if any.
- Refactors applied, encodings added.
- Constraints left unenforced and other open work.
- `git diff --stat` for the change.

## Rules

1. Edit comments, suppressions, and the smallest code change that makes them unnecessary. Nothing else.
2. Never widen the fence. Instances of the same problem outside the scope get reported, not fixed.
3. Never rewrite a comment into a shorter comment. Delete it or prove it is a keep.
4. Never restore a deletion on a hunch. A keep needs proof the constraint is about something we cannot change.
5. Never commit. Leave the working tree for the user to review.
6. If the suite cannot run, say so plainly and report what is unverified.

## Composition

- **Invoke after:** `/verify` flags comment findings, or directly before opening a PR.
- **Pairs with:** `/unslop` for prose and `/verify` for the full pre-merge pass. `/no-comments` owns comments; the other two do not touch them.

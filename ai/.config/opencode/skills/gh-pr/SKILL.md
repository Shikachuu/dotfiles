---
name: gh-pr
description: Use when opening a GitHub pull request, writing or rewriting a PR description or title, recording QA results on a PR, or deciding whether a draft PR is ready for review. Activate when the user says "open a PR", "create the PR", "raise a pull request", "write the PR description", "rewrite the PR body", "update the PR title", "add QA results to the PR", "wrap up the PR", or "mark the PR ready". Do not use for reviewing someone else's PR, replying to review comments, or GitHub Actions workflows.
---

# GitHub pull request

Open the PR as a draft, finish and verify the work, write the description in the fixed shape
below, and leave the ready decision to the user. Asking for this skill is the explicit ask to
push and open the PR. Marking it ready is a separate ask.

## 1. Branch and draft

Find the base first. The base is the repo's default branch, or the parent branch when the PR
stacks on another one.

```bash
base=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name)
git fetch origin
git checkout -b <type>/<slug> "origin/$base"   # type: feat|fix|chore|refactor
```

Never work on the base branch itself. If the work is already committed on a feature branch,
keep that branch.

Open the draft as soon as the branch has a commit. When the repo deploys a preview per PR,
open it before the work with an empty commit, so the preview builds while you work:

```bash
git commit --allow-empty -m "chore: start <slug>"
git push -u origin HEAD
gh pr create --draft --base "$base" --title "<title>" --body-file <stub>
gh pr view --json isDraft,url
```

The stub body is one line on what is coming, then the attribution footer. Check `isDraft`
once after creation. Do not change draft status again until the user asks.

## 2. Finish the work

- Sync with the base: `git fetch origin && git rebase "origin/$base"`. Resolve conflicts, then
  `rg -n '^<<<<<<< '` must return nothing.
- Format and lint the touched files with the project's tools. Run the project's tests and
  build. Green before the description is written.
- Run `/no-comments`, then `/verify` on non-trivial changes. Apply the fixes and re-run the
  tests. Keep the verdict for the chat report.
- Docs: when the change alters behavior a README or docs page describes, update that page in
  the same PR.
- Push with `git push --force-with-lease` after a rebase. Never `--force`.

## 3. Title

`type(scope): description`, lowercase, present tense, matching the repo's commit style.

- Take scopes from the repo's commitlint config (`.commitlintrc*`, `commitlint.config.*`) when
  one exists. List every touched scope, comma-separated: `feat(api,frontend): ...`.
- No commitlint config: use one scope when the change sits in one area, otherwise drop it.

## 4. Description

The visible part is 150 words maximum, in this order. Each part is a slot: fill it or drop it.
Never add a section.

````markdown
<One to three sentences: what changed and why. Ticket or issue reference if one exists.>

**Production diff: +<a> / -<d> in <k> files** (tests, docs, generated code and lockfiles excluded)

```mermaid
flowchart LR
  <one chart, 8 nodes maximum, the reviewer's first picture of the change>
```

### How to review
1. <step, what to see>
2. <..., 5 steps maximum>

<details><summary>QA</summary>

| Step | Result |
|---|---|
| <acceptance item> | pass: <what was observed, where> |
</details>

<details><summary>Verification</summary>

<commands run, test and build results, /verify verdict>
</details>

<details><summary>Decisions and trade-offs</summary>

- <rejected alternative and why>
</details>

<details><summary>Follow-ups</summary>

- <known gap left out of this PR, with the reason>
</details>

<attribution footer, if the harness specifies one>
````

Rules for the slots:

- Each `<details>` block is one aspect a reader may choose to open. An empty aspect gets no
  block.
- Evidence, ids, numbers, commands and logs go only inside a block, never in the visible part.
- Drop the mermaid chart when one sentence already explains the change. Draw it when the
  change crosses components or alters a flow.
- "How to review" lists steps a reviewer can follow: a URL to open, a command to run, a file
  to read first. Drop it for a change the diff alone explains.
- QA rows record only what you ran and observed. Write `fail` or `not run` plainly; never
  claim a pass you did not see.
- Follow the writing rules from the global instructions. Run the unslop skill over the body
  before setting it.

Production diff, against the PR's own base (the parent branch for a stacked PR):

```bash
git diff --numstat "origin/$base...HEAD" -- . \
  ':!**/test/**' ':!**/tests/**' ':!**/__tests__/**' ':!**/*.test.*' ':!**/*_test.*' ':!**/*.spec.*' \
  ':!docs/**' ':!**/*.md' ':!**/generated/**' \
  ':!*.lock' ':!**/*.lock' ':!**/package-lock.json' ':!**/pnpm-lock.yaml' ':!**/go.sum' \
  | awk '{a+=$1; d+=$2; f++} END {printf "+%d / -%d in %d files\n", a, d, f}'
```

Add the repo's own generated or vendored paths to the exclusions when it has them.

Write the body to a file in the scratchpad, then set title and body together:

```bash
gh pr edit <n> --title "<title>" --body-file <file>
```

## 5. Ready for review

Leave the PR as a draft. Report to the user:

- the PR URL and title,
- the `/verify` verdict and anything it flagged that you did not fix,
- QA rows that failed or were not run.

Run `gh pr ready <n>` only when the user says to.

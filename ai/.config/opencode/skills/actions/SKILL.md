---
name: actions
description: Use when creating, editing, reviewing, debugging, or splitting GitHub Actions CI/CD workflows and composite actions under .github/ (workflow YAML, jobs, matrix builds, runners). Activate when the user says "set up CI for this repo", "add a CI/CD or deploy workflow", "pin actions to commit SHAs", "this workflow is too big, split it up", "extract a reusable or composite action", "the pipeline / release-please is broken", "cache dependencies in CI", "add concurrency cancellation to PR checks", "only run jobs when certain paths change", "bump an action to the latest version", or "give a workflow a dynamic run name".
---

# GitHub Actions

Author and revise GitHub Actions in a consistent, correct house style. This skill is
procedural: **research first, then author**. Do not skip the research steps - they prevent
the most common drift and breakage.

## Step 0: Research the repo's tooling (mandatory)

Before writing any pipeline, investigate how the project actually builds, tests, lints, and
pins its toolchain. Discover the runtimes, package/version managers, task runners, and the
existing task commands from the repo itself. Do not assume a stack and do not start from a
checklist of tools to look for - naming candidates biases the result. Dispatch a research
agent for anything non-obvious.

Then make the CI lean on what already exists:

- Prefer the project's own commands (its lint/test/build entrypoints) over re-implementing
  the same logic inline in YAML.
- If a needed command is missing or doesn't fit CI exactly, add it to the project's manifest
  so local and CI share one source of truth, rather than hand-rolling bespoke CI logic.
- Mirror the project's toolchain installation in CI (whatever version/toolchain manager the
  repo already uses to pin its runtimes).

**Ambiguity -> ask, never guess.** If two sources pin different versions of the same tool
(and one might be gitignored), or the intended manager is unclear, surface the conflict and
ask the user. Do not pick for them.

There is one real tradeoff to flag: dedicated `setup-*` actions are often much faster than
re-installing via the repo's general toolchain manager. Default to parity with local tooling,
but raise the speed tradeoff when it's material and let the user decide.

## Step 1: Resolve every external action to its latest SHA (mandatory, every time)

All external actions and reusable workflows MUST be pinned by full commit SHA, never by tag.
This applies to first-party `actions/*` too, not only third-party. Never reuse a SHA from
memory - resolve it fresh each time you introduce or bump an action.

Use `gh` for the lookup:

```bash
# latest release tag
gh release view --repo OWNER/REPO --json tagName --jq .tagName
# that tag's commit SHA
gh api repos/OWNER/REPO/commits/<tag> --jq .sha
```

Then write the resolved SHA with the version as a trailing comment:

```yaml
# CORRECT
uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

# WRONG
uses: actions/cache@v4
```

> SHA pinning blocks automatic patch updates; pair it with Dependabot/Renovate if the repo
> wants the pinned SHAs kept current.

## File splitting

Split by **domain and cadence**, not by trigger count or a line tally.

- **Always separate distinct domains/cadences:** deploy vs. test/CI vs. validation/governance.
  They have different failure modes, concurrency rules, and review needs.
- **Keep same-cadence work in one file.** Prefer a single workflow with multiple `on:`
  triggers plus `if:` guards over one-file-per-trigger. Only split same-domain work when
  cadence, concurrency policy, or job shape genuinely differ.
- **~200 lines is a soft signal** to go looking for a natural split, not a hard rule.
- Otherwise bundle aggressively (fuzzy-search navigation). Use descriptive, greppable names:
  `ci.yml`, `deploy.yml`, `release.yml`, `governance.yml`.

## Composite / local actions (DRY)

Extract a repeated **multi-step** sequence (e.g. install runtime -> auth to private registry
-> install deps) into `.github/actions/<name>/action.yml` to kill config and pipeline drift.

- **Never wrap a single step** - that's bloat, not reuse.
- Composite action = shared *setup steps* in the caller's job context.
- Reusable workflow = a shared *job* (its own `runs-on`, inputs/outputs).
- Caveat: composites don't take `secrets:` the way reusable workflows do; if a shared unit
  needs secrets passed in cleanly, use a reusable workflow.

## Concurrency

Group by runtime constraint (e.g. all PR checks share a group) and cancel superseded runs to
save minutes:

```yaml
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
```

**Deploys MUST NEVER cancel in progress.** A canceled deploy can leave a partially-applied
release. Serialize instead - use `cancel-in-progress: false` and a stable per-environment
group key so deploys queue rather than abort.

## Naming and run-names

- Every job and every step has a `name`.
- Set a dynamic `run-name:` templated from context so runs are identifiable in the UI.
  `run-name` can only read the `github.*` and `inputs.*` contexts (not job/step outputs), so
  the values you template on must come from there.

```yaml
run-name: "Tests (PR #${{ github.event.pull_request.number }})"
```

## Caching: close the gap

Audit every tool in the CI stack for a cache and wire up the missing ones. Two patterns:

- **Dependency caches** key on the lockfile, no run id:
  `key: ${{ runner.os }}-deps-${{ hashFiles('<lockfile>') }}`.
- **Incremental tool caches** (golangci-lint, build caches) use a rolling key. GH caches are
  immutable, so a stable key never absorbs new entries; putting `github.run_id` in the primary
  key forces a fresh save every run, while `restore-keys` fall back to the latest prefix match:

```yaml
- name: Cache golangci-lint
  uses: actions/cache@<resolve-sha> # vX.Y.Z
  with:
    path: ~/.cache/golangci-lint
    key: ${{ runner.os }}-golangci-${{ hashFiles('.golangci-lint.yml', 'mise.toml') }}-${{ github.run_id }}
    restore-keys: |
      ${{ runner.os }}-golangci-${{ hashFiles('.golangci-lint.yml', 'mise.toml') }}-
      ${{ runner.os }}-golangci-
```

Prefer a setup action's built-in cache when it exists and fits the need.

## Monorepo conditional execution

Run only what changed to save minutes. Use `dorny/paths-filter` (SHA-pinned): a filter job
emits boolean outputs, and downstream jobs gate on them.

```yaml
jobs:
  changes:
    name: Detect changes
    runs-on: ubuntu-latest
    outputs:
      backend: ${{ steps.filter.outputs.backend }}
    steps:
      - name: Filter changed paths
        uses: dorny/paths-filter@<resolve-sha> # vX.Y.Z
        id: filter
        with:
          filters: |
            backend:
              - 'services/api/**'
  test-backend:
    name: Test backend
    needs: changes
    if: needs.changes.outputs.backend == 'true'
    runs-on: ubuntu-latest
    steps: [...]
```

## Security defaults (baked in)

- Default top-level `permissions: { contents: read }`; widen per-job only as needed
  (`contents: write` for releases, `id-token: write` for OIDC, etc.).
- Check out with `persist-credentials: false` unless a later step needs the token.

```yaml
permissions:
  contents: read
# ...
    steps:
      - name: Checkout
        uses: actions/checkout@<resolve-sha> # vX.Y.Z
        with:
          persist-credentials: false
```

## Comments

Avoid comments in workflow files. Only annotate genuine edge cases or hacky workarounds, kept
brief and factual (a reference link is welcome). The `# vX.Y.Z` after a pinned SHA is the
standard exception.

## Tooling

Prefer the `gh` CLI for all lookups (SHAs, releases, repo metadata).

## Final checklist

- [ ] Every external action SHA-pinned and freshly resolved (`# vX.Y.Z` trailing)
- [ ] `name` on every job and step
- [ ] Dynamic `run-name` using only `github.*` / `inputs.*`
- [ ] Concurrency grouped by runtime; PR checks cancel, deploys never cancel
- [ ] `permissions` least-privilege (read by default, widened per job)
- [ ] `persist-credentials: false` on checkout unless the token is needed
- [ ] Caches wired for every cachable tool; right key pattern per cache type
- [ ] Local tooling honored, or the user asked when ambiguous
- [ ] Split by domain/cadence; same-cadence work bundled
- [ ] Composite/reusable extraction only for repeated multi-step logic
- [ ] No stray comments

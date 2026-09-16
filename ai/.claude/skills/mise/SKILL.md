---
name: mise
description: Use when creating, editing, reviewing, or debugging mise (mise-en-place) config, tasks, or tool versions - mise.toml, tool pins, tasks, [env], the lockfile, and trust. Enforces one opinionated mise ruleset so every repo pins and runs its tools the same way. Activate when the user says "set up mise for this repo", "add a tool to mise.toml", "pin node or python with mise", "what's the mise registry name for X", "write a mise task", "set env vars in mise", "load a .env file with mise", "turn on the mise lockfile", "mise isn't picking up my config", "mise install or mise run is failing", or "migrate this repo from asdf or .tool-versions to mise", or edits mise.toml, mise.local.toml, mise.<env>.toml, mise.lock, .config/mise/config.toml, or files under mise-tasks/ or .mise/tasks/. Do not use for Homebrew or apt installs, Dockerfile base images, GitHub Actions workflow YAML, or npm, pip and cargo dependency installs.
---

# mise

mise is the one toolchain manager, task runner, and env manager for a repo. This skill is
procedural: **resolve names and backends first, then generate**. Never write a tool pin or a
backend prefix from memory, and never guess a version.

Facts here were checked against mise 2026.8.12. Where a behaviour is version-sensitive the
reference says so.

## Diagnose before you generate

Route to one reference instead of loading everything.

| The task / symptom | Load |
|---|---|
| "Is tool X in mise?", picking a backend, prefix syntax | `references/registry.md` |
| Which file wins, precedence, profiles, `[tools]` value forms | `references/config.md` |
| Writing tasks, task args, file tasks, `#MISE` headers | `references/tasks.md` |
| Env vars, dotenv, secrets, hooks, migrating off direnv | `references/env.md` |
| Lockfile flags, reproducible installs, the trust model | `references/lockfile-trust.md` |

## Core workflow

1. **Read what already loads.** `mise config ls` before editing anything. Precedence bugs are the
   most common mise failure and are invisible without it.
2. **Resolve every tool name.** `scripts/mise-tool-lookup.sh <name>` gives the backend, the real
   latest version, and the exact `[tools]` line. Do not skip this for "obvious" tools.
3. **Write `mise.toml`** in the house layout below.
4. **Add tasks** for every repeated command.
5. **Lock it.** `mise lock`, then commit `mise.toml` and `mise.lock` together.
6. **Run the gate.** `scripts/validate-mise.sh [dir]`.

## The house layout

```
mise.toml           committed, the only config a repo needs
mise.local.toml     machine-local overrides, gitignored, never committed
mise.<env>.toml     optional per-environment overrides, selected with `mise -E <env>`
mise.lock           committed, always
mise-tasks/         file tasks, each one executable
.env                gitignored, with a committed .env.example beside it
```

`.gitignore` gets exactly these three lines, and `mise.lock` must not be among them:

```
mise.local.toml
mise.*.local.toml
.env
```

One config per repo root. Nested `mise.toml` files make `mise config ls` the only way to answer
which version wins. Use `mise.<env>.toml` for variation instead.

## Tool pins and backends

- **Every runtime and CLI the repo needs goes in `[tools]`.** No "brew install X" in a README for
  anything mise can install.
- **Pin the major, e.g. `node = "26"`.** Never `latest` or `*` in a repo config; `latest` is fine
  in a personal global config. The repo pin states intent, `mise.lock` states the build.
- **Write the bare shorthand** whenever `mise registry <name>` resolves it. A bare name uses the
  registry's *first* backend, so only write it when that is the backend you want.
- **When you need an explicit prefix, prefer** `core` > `aqua` > `github` > `npm`/`cargo`/`pipx`/
  `go`/`gem`. Avoid `asdf`, whose plugins run arbitrary shell at install time, wherever an aqua
  recipe exists. `aqua` verifies checksums and signatures; that is why it outranks the rest.
- **Read `mise backends ls` rather than trusting a list.** The docs already mark `ubi` deprecated
  and describe a `packslip` backend that 2026.8.12 does not have. The lookup script does this.
- **Idiomatic version files stay off** unless a non-mise consumer needs the file. `.tool-versions`
  is read with no opt-in, so leftovers from an asdf migration silently win. Delete them.

## Lockfile

Set `[settings] lockfile = true`, run `mise lock`, and commit `mise.lock` next to `mise.toml`.
CI installs with `mise install --locked` (or `MISE_LOCKED=1`), which requires pre-resolved URLs and
makes no API calls to GitHub or aqua.

- `mise lock --bump` moves the lockfile. `mise upgrade --bump` moves the pin in `mise.toml`.
  They are different commands; pick deliberately.
- `mise lock --platform linux-x64,macos-arm64` before committing a pin change, when CI and the team
  do not share a platform. It resolves every tool for every platform over the network, so it is a
  pre-commit step, not something to run on every edit.
- Never hand-edit `mise.lock`. Prefer the lockfile over `mise use --pin`, as mise's own help does.

## Tasks

Three forms, in order of how much the task needs:

```toml
[tasks]
fmt = "cargo fmt"                      # one-liner, no metadata

[tasks.build]
description = "Build the release binary"   # required on every task
depends = ["fmt"]                          # runs in PARALLEL, no ordering guarantee
sources = ["src/**/*.rs", "Cargo.toml"]    # anything that compiles declares these
outputs = ["target/release/app"]
dir = "{{config_root}}"                    # same behaviour from a subdirectory
run = "cargo build --release"
```

Past roughly five lines or any real control flow, move it to `mise-tasks/<name>` as a script. A long
`run` array in TOML loses shellcheck, editor support, and readable diffs.

**A file task must be executable.** Without the executable bit the script never appears in
`mise tasks ls`. `mise run <name>` does name the cause, so check there when a task seems to vanish.

`depends` gives no ordering guarantee, so anything order-dependent needs an explicit chain or
`wait_for`. Task arguments use the `usage` field or a `#USAGE` header, never the Tera helpers.
See `references/tasks.md`.

## Env vars

`[env]` in `mise.toml` is the default. There are exactly four `_` modules: `_.file`, `_.path`,
`_.python`, `_.source`.

```toml
[env]
NODE_ENV = "development"
_.file = ".env"                        # secrets and machine-local values only
_.path = "./bin"                       # relative to config_root, not cwd
DATABASE_URL = { required = "set DATABASE_URL to the local postgres URL" }
API_TOKEN = { value = "...", redact = true }

redactions = ["*_TOKEN", "*_SECRET"]   # top level, not inside [env]
```

A `required` var fails with your message instead of silently becoming an empty string. In CI prefer
`task.output = "prefix"` over `raw`, because raw bypasses redaction.

Do not add direnv to a repo that lacks it. mise's direnv integration is deprecated upstream, and
both tools hook the shell and fight over PATH. `references/env.md` has the migration table.

## Trust

Verified on 2026.8.12: `[tools]` and plain `[tasks]` are "safe" and need no trust, while **`[env]`
and `[settings]` both require it.** Any config that sets the lockfile or an env var will therefore
prompt on first use. That is expected, not a mistake.

- Run `mise trust` once per clone, and say so in the repo README when a config needs it.
- Put `lockfile = true` in your own global config so your repos get lockfiles without every repo
  config carrying a `[settings]` block. Put it in the repo config when the team must have it, and
  accept the trust step.
- Auto-trust your own tree with `settings.trusted_config_paths` in the global config.
- Never `mise trust -a`.

## Deprecated forms, never write these

mise still accepts most of these and only warns, so they look correct until they are removed.

| Do not write | Write instead |
|---|---|
| `[alias]` | `[tool_alias]` for versions, `[shell_alias]` for shell aliases |
| top-level `env_file`, `dotenv`, `env_path` | `[env] _.file`, `[env] _.path` |
| `_.venv` | `_.python.venv = { path = ".venv", create = true }` |
| `{{ arg(...) }}`, `option()`, `flag()` in `run` | the `usage` field, or `#USAGE` in a file task |
| `ubi:owner/repo` | `aqua:owner/repo` or `github:owner/repo` |
| `mise init` | `mise generate config`, or `mise use <tool>@<ver>` |

`mise init` does not exist. Do not suggest it.

## Scripts

- `scripts/mise-tool-lookup.sh <name> [<name>...]` - backend, real latest version, and the exact
  `[tools]` line. Falls back to fuzzy search on a miss instead of dead-ending.
- `scripts/validate-mise.sh [dir]` - the gate: deprecated forms, what loads, resolved versions,
  task validity and descriptions, non-executable file tasks, lockfile presence, gitignore
  correctness, trust and doctor.

Both need `mise` and `jq` and fail fast without them.

## CI

CI runs `mise install --locked` then `mise run <task>`, rather than restating the commands. Cache
keys use `hashFiles('mise.lock')`. Workflow YAML itself belongs to the `actions` skill.

## Don't

- Don't write a tool name or backend prefix from memory. Run the lookup script.
- Don't use `latest` or `*` in a repo config.
- Don't commit `mise.local.toml`, and don't gitignore `mise.lock`.
- Don't hand-edit `mise.lock`, and don't confuse `mise lock --bump` with `mise upgrade --bump`.
- Don't create a task without a `description`.
- Don't rely on `depends` for ordering.
- Don't leave a `mise-tasks/` script non-executable.
- Don't add direnv to a repo that does not already have it.
- Don't suggest `mise init`; it does not exist.
- Don't run `mise trust -a`.

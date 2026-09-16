# Lockfile and trust

## mise.lock

Create it with `mise lock` and commit it. Do not set `[settings] lockfile = true` in a repo config.

Measured on 2026.8.12: with no `lockfile` setting anywhere, `mise lock` still creates `mise.lock`,
and a later `mise install` adds newly declared tools to it automatically. The setting only makes
mise create a lockfile that does not exist yet. Since a repo commits its lockfile, every clone
already has one, so the setting buys nothing and costs the config its trust-free status.

The lockfile name mirrors the config: `mise.toml` gives `mise.lock`, `mise.test.toml` gives
`mise.test.lock`. Dependency sidecars live in `.mise/locks/`.

```toml
lockfile_version = 1

[[tools.node]]
version = "26.8.1"
backend = "core:node"
specifiers = ["26"]

[tools.node."platforms.macos-arm64"]
checksum = "sha256:6e577fd0d9db776db8230..."
url = "https://nodejs.org/dist/v26.8.1/node-v26.8.1-darwin-arm64.tar.gz"
```

Commands:

```sh
mise lock                                   # refresh checksums and URLs for the locked versions
mise lock node python                       # only these tools
mise lock --bump                            # re-resolve latest/lts/prefixes; does NOT touch mise.toml
mise lock --bump --dry-run --json           # detect available updates in CI
mise lock --platform linux-x64,macos-arm64  # pre-populate other platforms before committing
mise lock --minimum-release-age 90d
mise lock --local                           # mise.local.lock instead
mise install --locked                       # or MISE_LOCKED=1, or settings.locked = true
```

`mise lock --bump` moves the lockfile. `mise upgrade --bump` rewrites the pin in `mise.toml`. They
are different operations; pick deliberately.

`--locked` requires pre-resolved URLs for the current platform and fails otherwise, which also means
no API calls to GitHub or the aqua registry. That is the point in CI: deterministic and offline.

`mise lock --platform` resolves every tool for every listed platform over the network. On a repo
with many tools against unauthenticated GitHub it will hit rate limits, so run it when a pin
changes, not on every edit.

Never hand-edit `mise.lock`. Prefer the lockfile over `mise use --pin`, as mise's own help does.
`[tool_config] locked = true` enforces lockfile resolution for one config root.

## Trust

Verified on mise 2026.8.12 by running each variant:

| Config contains | Trust needed |
|---|---|
| `[tools]` with string values (`node = "26"`) | no |
| `[tools]` with list values (`python = ["3.12"]`) | no |
| `[tools]` with an inline table (`go = { version = "1.21" }`) | **yes** |
| `[tools.x]` as its own section | **yes** |
| `[tasks]` without templates or tool options | no |
| `[env]` | **yes** |
| `[settings]` | **yes** |
| `[vars]` | **yes** |
| `[hooks]` | **yes** |

Confirmed as not requiring trust: `min_version`, top-level `redactions`, a task with its own `env`
table, and a `mise-tasks/` file task.

A plain tools-and-tasks config never prompts. The first tool option, env var, var or hook changes
that, which is a reason to reach for them only when needed rather than a reason to avoid them.

```sh
mise trust                  # trust the config here or in a parent
mise trust --show           # report status, change nothing
mise trust --untrust
mise trust --ignore         # never trust, ignore going forward
```

- In normal mode `mise run`, a bare `mise <task>`, `mise install`, `mise exec` and `mise watch`
  automatically trust their active config.
- An untrusted config skips template `exec()` and `read_file()`, task execution, tool postinstall
  hooks, project env vars and shell aliases, and any project setting that weakens verification.
  The global and system config still apply.
- Trust is shared across git worktrees: a linked worktree inherits the main checkout's trust.
- `settings.trusted_config_paths = ["~/work"]` auto-trusts a subtree. This is the right place for
  your own repos.
- `settings.paranoid` binds trust to file content and rechecks provenance, and disables the worktree
  sharing above.
- `settings.minimum_release_age = "7d"` blocks freshly published versions. Explicit versions and
  existing lockfile entries bypass it.
- Never run `mise trust -a`. It trusts the current directory, its parents and its subdirectories in
  one go.

For a repo that needs `[env]`, note the one-time `mise trust` in the README, and add the repo's
parent directory to `settings.trusted_config_paths` in your own global config so your clones stop
asking.

Verification is built in for aqua, node and swift: checksums plus Cosign, Minisign or OpenPGP
signatures and SLSA provenance. `locked_verify_provenance` forces a recheck rather than reusing what
the lockfile recorded.

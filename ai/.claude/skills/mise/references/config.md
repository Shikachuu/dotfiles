# Config files

## Which file wins

Highest first, within one directory:

```
mise.local.toml
mise.toml
mise/config.toml
mise/conf.d/*.toml           alphabetical
.mise/config.toml
.mise/conf.d/*.toml
.config/mise.toml
.config/mise/config.toml
.config/mise/conf.d/*.toml
~/.config/mise/config.toml   global
/etc/mise/config.toml        system
```

A child directory beats a parent directory. `.mise.toml` with the leading dot is still read as a
legacy name; write `mise.toml`.

`mise config ls` reports what actually loaded. Run it before editing and whenever a version is not
what you expect. It is the only reliable answer to "which file set this".

`~/.config/mise/config.toml` is the global config. A file at `~/.config/mise.toml` is not the global
config: it loads as a *project* config for the `$HOME` directory, so `mise use -g` will not write
to it.

## Environments

`MISE_ENV` or `-E/--env` selects extra files. Within one directory:

```
mise.{ENV}.local.toml > mise.local.toml > mise.{ENV}.toml > mise.toml
```

```sh
MISE_ENV=production mise exec -- sh -c 'echo $APP_MODE'
mise -E production config ls
mise -E ci,test run build        # comma separated, last wins
```

`MISE_ENV` cannot be set inside `mise.toml`, since it decides which files load. The global config
uses `config.{ENV}.toml`.

## Top-level sections

`min_version`, `tools`, `env`, `vars`, `tasks`, `task_config`, `task_templates`, `settings`,
`tool_alias`, `shell_alias`, `plugins`, `hooks`, `watch_files`, `redactions`, `tool_config`,
`monorepo`, `bootstrap`, `wrappers`, `deps`, `oci`, `dotfiles`, `history`, `doctor`, `daemons`.

```toml
min_version = { soft = "2026.1.0" }

[tools]
node = "26"
python = ["3.11", "3.12"]                 # first wins on PATH
ruby = { version = "3", postinstall = "gem install bundler" }
go = { version = "1.21", os = ["linux", "macos"] }

[vars]
prefix = "dev"
database_url = "postgres://localhost/{{ vars.prefix }}_db"

[settings]
lockfile = true
idiomatic_version_file_enable_tools = ["node"]

[tool_alias.node.versions]
team_default = "22"                       # mise install node@team_default

[shell_alias]
gs = "git status"
```

Use `min_version` only when the config uses a key newer than about a year, and prefer the `soft`
form. mise releases weekly, so a hard pin to whatever version happened to be installed rejects a
colleague's working mise for no reason. `min_version = { hard = "..." }` is for a feature floor you
can name.

`[tools]`, `[env]` and `[settings]` merge additively with the child overriding the parent per key.
They do not union: a list-valued setting in a higher-precedence file replaces the lower one outright
rather than appending to it.

`mise settings` has 167 keys. Do not enumerate them; read
<https://mise.jdx.dev/configuration/settings.html> or run `mise settings`.

## Idiomatic version files

Off by default. `.nvmrc`, `.python-version`, `.ruby-version`, `go.mod`, `rust-toolchain.toml` and
friends are ignored until you opt in per tool:

```sh
mise settings add idiomatic_version_file_enable_tools python
```

`.tool-versions` is read with **no** opt-in. During an asdf migration, delete it once the tools are
in `mise.toml`, or it keeps winning silently.

## Creating a config

There is no `mise init`.

```sh
mise generate config                  # writes mise.toml here
mise generate config -g               # global, ~/.config/mise/config.toml
mise generate config -n                # dry run
mise generate config -t .tool-versions # import from asdf
mise use node@26                       # install + write, creating mise.toml if absent
mise use -g node@26                    # global
mise use --env staging node@26         # writes mise.staging.toml
mise use --remove node
```

`mise use` picks its target in this order: `--global`, `--path`, `--env <env>`,
`MISE_DEFAULT_CONFIG_FILENAME`, the first of `MISE_OVERRIDE_CONFIG_FILENAMES`, then `mise.toml`.

## Deprecated, do not write

| Do not write | Write instead |
|---|---|
| `[alias]` | `[tool_alias]`, `[shell_alias]` |
| top-level `env_file`, `dotenv`, `env_path` | `[env] _.file`, `[env] _.path` (removal 2027.x) |
| `_.venv` | `_.python.venv` |
| `{{ arg() }}`, `option()`, `flag()` in `run` | the `usage` field (removal 2027.5.0) |
| `ubi:owner/repo` | `aqua:` or `github:` |

`validate-mise.sh` greps for all five. That grep is the canonical list; keep the two in sync when
mise deprecates something new.

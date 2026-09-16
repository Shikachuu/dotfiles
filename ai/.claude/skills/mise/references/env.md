# Environment variables

## The four modules

`[env]` has exactly four `_` modules: `_.file`, `_.path`, `_.python`, `_.source`. There is no
`_.venv`; the virtualenv key is `_.python.venv`.

```toml
[env]
NODE_ENV = "production"
PORT = 3000
OLD_VAR = false                              # unset the variable
DEBUG = { default = "false" }                # only if currently unset or empty
DATABASE_URL = { required = true }
API_KEY = { required = "Get a key at https://example.com/keys" }
SECRET = { value = "hunter2", redact = true }
NODE_PATH = { value = "{{ tools.node.version }}", tools = true }

_.file = ".env"
_.file = ['.env', { path = ".secrets.yaml", redact = true }]
_.path = './bin'
_.path = ['tools/bin', { path = "{{env.GEM_HOME}}/bin", tools = true }]
_.source = './script.sh'
_.python.venv = { path = ".venv", create = true }

redactions = ["SECRET_*", "*_TOKEN", "PASSWORD"]   # TOP LEVEL, not inside [env]
```

- `_.file` reads dotenv, JSON, YAML or TOML, chosen by extension. Options: `path`, `redact`,
  `tools`, `expand`.
- `_.path` resolves relative entries against `config_root`, not the current directory.
- `_.source` runs `source` and is bash-only.
- `tools = true` defers evaluation until after tools have set up their environment. Needed to
  reference anything a tool provides, such as `GEM_HOME`.
- Variables resolve top to bottom. Tera templates (`{{config_root}}`, `{{env.X}}`, `{{vars.x}}`,
  `{{tools.node.version}}`) and shell expansion (`$VAR`, `${VAR:-default}`) both work; shell
  expansion is governed by the `env_shell_expand` setting.
- A `required` failure is a hard error for normal commands but only a warning during shell
  activation.

## Secrets

Keep secrets out of `mise.toml`. Put them in `.env`, gitignore it, and commit a `.env.example`
naming the keys.

Declare anything sensitive with `redact = true` and add a top-level `redactions` list so the values
are masked in task output. In CI use `task.output = "prefix"` rather than `raw`, because raw mode
connects the process directly to the terminal and bypasses redaction entirely.

`mise env --redacted --values` deliberately prints real values. Do not paste its output anywhere.

## Hooks

`[hooks]` covers what a direnv `.envrc` would script.

```toml
[hooks]
cd = "echo changed dirs"
enter = { task = "setup" }
postinstall = { run = "echo installed", shell = "bash -c" }

[hooks.enter]
shell = "bash"
script = ["source completions.sh", "export PROJECT_READY=1"]

[[watch_files]]
patterns = ["src/**/*.rs"]
run = "cargo fmt"
```

`enter`, `leave`, `cd` and `watch_files` need `mise activate`. `preinstall` and `postinstall` do
not. `run` spawns a subprocess; `script` with a shell name modifies the current shell.

## Trust

`[env]` pushes a config out of mise's "safe" set, so a config with env vars needs `mise trust` on
first use. That is expected. See `lockfile-trust.md`.

## direnv

**mise's direnv integration is deprecated upstream.** The mise docs state that compatibility issues
are not treated as mise bugs and that direnv compatibility pull requests are not accepted. Do not
add direnv to a repo that does not already have it.

For a repo that already uses direnv, migrate:

| direnv | mise |
|---|---|
| `export NODE_ENV=development` | `[env] NODE_ENV = "development"` |
| `dotenv .env` | `[env] _.file = ".env"` |
| `PATH_add bin` | `[env] _.path = "bin"` |
| sourcing a script | `[env] _.source = "./script.sh"` |
| `layout python` | `[env] _.python.venv = { path = ".venv", create = true }` |
| `.envrc` shell scripting | `[hooks] enter` |

Legacy activation, if you must keep both for a while:

```sh
mkdir -p ~/.config/direnv/lib
mise direnv activate > ~/.config/direnv/lib/use_mise.sh
echo 'use mise' > .envrc
```

Known conflicts: both hook the shell and fight over adding and restoring `PATH`; direnv's
`layout python` clashes with mise's python selection; changes to `.tool-versions` outside the
`.envrc` directory may not retrigger direnv; `use mise` hands direnv control of exports and does not
reproduce everything `mise activate` does. Verify any migration with a fresh shell plus
`mise exec -- <cmd>`.

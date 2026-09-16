# Tasks

## TOML tasks

```toml
[tasks]
fmt = "cargo fmt"                          # shorthand string
lint = ["cargo fmt --check", "cargo clippy"]   # array: series, fail fast

[tasks.test]
description = "Run the test suite"         # required on every task
alias = "t"
depends = ["build"]                        # PARALLEL, no ordering guarantee
depends_post = ["cleanup"]                 # after this task
wait_for = ["migrate"]                     # before, but only if already scheduled
run = [
  "cargo test",
  "./scripts/test-e2e.sh",
]
run_windows = "cargo test"
dir = "{{config_root}}"                    # or "{{cwd}}" for the invoking directory
env = { RUST_BACKTRACE = "1" }
tools = { rust = "1.80" }                  # installed just for this task
sources = ["src/**/*.rs", "Cargo.toml"]
outputs = ["target/debug/app"]
shell = "bash -c"
timeout = "5m"
confirm = "Really deploy to prod?"
quiet = false
raw = false                                # connects stdin/stdout directly, bypasses redaction
```

Full field list: `alias, confirm, depends, depends_post, wait_for, description, dir, env, vars,
tools, hide, outputs, cache, output, quiet, silent, interactive, raw, raw_args, run, run_windows,
file, sources, watch, shell, usage, timeout`, plus sandboxing keys `deny_all, deny_read, deny_write,
deny_net, deny_env, allow_read, allow_write, allow_net, allow_env, pass_through_env`. The sandboxing
keys and `raw_args` are recent; confirm against `mise tasks --help` on the local build before using
them.

Notes:

- Tasks run under `set -e` when the shell is sh, bash or zsh. Use `set +e` to opt out.
- `sources` plus `outputs` makes mise skip a task whose inputs are unchanged. `mise run -f` forces.
- `depends` gives no ordering guarantee. Anything order-dependent needs an explicit chain or
  `wait_for`.
- A multi-line `run` beginning with a shebang runs in that language.
- `[task_templates.<name>]` plus `extends = "<name>"` shares config between tasks.
- `[task_config]` keys: `includes`, `excludes`, `dir`, `shell`, `cascade`, `cache`, `global_env`.

## Task arguments

Use the `usage` field. The Tera `arg()`, `option()` and `flag()` functions inside `run` are
deprecated, with removal planned for 2027.5.0.

```toml
[tasks.test]
usage = '''
arg "<file>" help="Test file to run" default="all"
flag "-v --verbose" help="Enable verbose output"
flag "--format <format>" help="Output format" default="text"
'''
run = 'echo "testing ${usage_file?} format=${usage_format:-text}"'
```

Parsed values arrive as `usage_*` environment variables.

## File tasks

Search directories: `mise-tasks/`, `.mise-tasks/`, `mise/tasks/`, `.mise/tasks/`,
`.config/mise/tasks/`. Extend with `task_config.includes`.

**Every file task must be executable.** Without the executable bit the script is absent from
`mise tasks ls` entirely. `mise run <name>` is the one place mise explains why:
`no task <name> found, but a non-executable file exists at ...`. `chmod +x` is part of creating one.

Subdirectories become colon-namespaced names, and `_default` is the directory's default:

```
mise-tasks/
├── build           -> build
└── test/
    ├── _default    -> test
    ├── integration -> test:integration
    └── units       -> test:units
```

Headers use TOML syntax in comments:

```bash
#!/usr/bin/env bash
#MISE description="Build the CLI"
#MISE alias="b"
#MISE depends=["lint", "test"]
#MISE sources=["Cargo.toml", "src/**/*.rs"]
#MISE outputs=["target/debug/app"]
#MISE env={RUST_BACKTRACE = "1"}
#MISE tools.rust="1.80"
#MISE dir="{{config_root}}"
set -euo pipefail
cargo build
```

Directives: `description, alias, depends, depends_post, wait_for, sources, outputs, dir, env, hide,
raw, quiet, confirm, tools`. Multi-line lists repeat the prefix. Dotted keys such as
`#MISE tools.node="20"` avoid inline tables.

Arguments use `#USAGE`:

```bash
#USAGE flag "-c --clean" help="Clean before building"
#USAGE flag "-p --profile <profile>" help="Build profile" default="dev" {
#USAGE   choices "dev" "release"
#USAGE }
#USAGE arg "<target>" help="The target to build"
#USAGE arg "[environment]" env="DEPLOY_ENV" default="development"

[ "${usage_clean:-false}" = "true" ] && cargo clean
cargo build --profile "${usage_profile?}"
```

Precedence for an `env=`-backed arg: CLI argument, then environment variable, then default. Without
`#USAGE`, extra arguments pass through as `$1` and `$@`.

Other languages use their own comment character:

```javascript
#!/usr/bin/env -S node
//MISE description="Write a greeting"
//USAGE arg "<output_file>" help="The file to write"
const { usage_output_file } = process.env;
```

## Running

```sh
mise run build            # or `mise r build`, or bare `mise build`
mise run                  # runs the task named `default`
mise run task1 a ::: task2 b   # ::: separates multiple tasks
mise run build -- --extra
mise run -f build         # ignore the sources/outputs cache
mise watch build
mise tasks ls | info <name> | deps | add | edit | validate
```

Available inside a task: `MISE_ORIGINAL_CWD`, `MISE_CONFIG_ROOT`, `MISE_PROJECT_ROOT`,
`MISE_TASK_NAME`, `MISE_TASK_FILE`, `MISE_TASK_DIR`.

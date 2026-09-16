# Registry and backends

Resolve a tool name before writing it. `scripts/mise-tool-lookup.sh <name>` does everything on this
page in one call; read on when you need to do it by hand or the script's answer needs judgement.

## The two commands do different jobs

```sh
mise registry                 # every tool: `name  backend:spec [backend:spec ...]`
mise registry ripgrep         # EXACT match only, prints the specs, exits 1 on a miss
mise registry --json ripgrep  # {short, backends[], description, aliases[]}
mise registry -b npm          # only tools available from one backend
mise search -m contains rip   # fuzzy; prints descriptions but NO backends
mise search -m equal node     # match types: equal, contains, fuzzy (default)
```

`registry` gives backends but cannot fuzzy match. `search` fuzzy matches but gives no backends.
Neither alone answers "what do I write in `[tools]`", which is why the lookup script uses both.

A bare shorthand in `[tools]` resolves to the **first** backend in the registry's list. Write the
shorthand only when that first backend is the one you want.

## Backends on 2026.8.12

`mise backends ls` is the source of truth. On this build:

```
aqua asdf cargo conda core dotnet forgejo gem github gitlab go npm pipx pkgx spm http s3 ubi vfox
```

Spread across the 1012 registry entries: aqua 697, asdf 622, github 221, cargo 87, vfox 58, npm 48,
pipx 32, go 24, http 14, core 14, conda 14, gem 3, spm 2, gitlab 1.

The docs and the binary disagree, which is why you read the binary. The docs mark `ubi` deprecated
and describe a `packslip` backend that this build does not have.

## Prefix syntax

| Backend | Example | Notes |
|---|---|---|
| core | `core:node` | built in: node, python, ruby, go, java, deno, bun, rust, erlang, zig |
| aqua | `aqua:BurntSushi/ripgrep` | curated, verifies checksums and signatures |
| github | `github:owner/repo` | release assets |
| gitlab | `gitlab:user/project` | |
| forgejo | `forgejo:instance/user/repo` | |
| npm | `npm:@biomejs/biome` | |
| cargo | `cargo:ripgrep` | builds from source |
| pipx | `pipx:black` | |
| go | `go:github.com/rhysd/actionlint/cmd/actionlint` | full import path |
| gem | `gem:rubocop` | |
| http | `http:tool-name` | URL-defined |
| s3 | `s3://bucket/tool` | |
| ubi | `ubi:owner/repo[exe=rg]` | deprecated upstream, do not write |
| vfox | `vfox:mise-plugins/vfox-1password` | plugin, runs shell |
| asdf | `asdf:mise-plugins/mise-poetry` | legacy plugin, runs arbitrary shell at install |

## Preference order

`core` > `aqua` > `github` > `npm`/`cargo`/`pipx`/`go`/`gem` > everything else, with `asdf` last.

core needs no network plugin and mise maintains it. aqua verifies checksums and signatures. asdf
plugins execute arbitrary shell during install, so prefer anything else when it exists. The lookup
script applies this order after intersecting with `mise backends ls`.

When the preferred backend is not the registry default, the script says so and emits an explicit
pin. `poetry` is the standard example: the registry defaults to `vfox:mise-plugins/vfox-poetry`,
while `pipx:poetry` is preferable.

## Writing the result

```toml
[tools]
node = "26"                          # registry default is core:node, so shorthand is right
ripgrep = "15"                       # registry default is aqua:BurntSushi/ripgrep
"pipx:poetry" = "2"                  # explicit: the default would have been vfox
"npm:@biomejs/biome" = "2"
"ubi:BurntSushi/ripgrep" = { version = "14", exe = "rg" }   # deprecated, shown for recognition only
```

Other `[tools]` option keys: `version`, `path`, `prefix`, `ref`, `os`, `minimum_release_age`,
`version_order`, plus backend-specific ones such as `exe`.

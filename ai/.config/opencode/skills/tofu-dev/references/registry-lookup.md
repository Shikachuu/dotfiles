# Registry lookup

Look up real provider/module/resource facts before writing HCL or test assertions. Use these
scripts (cheaper than an MCP) - they hit the OpenTofu Registry API at `https://api.opentofu.org`,
are unauthenticated GETs, cache well, and fail fast if `curl`/`jq` are missing.

Override the base URL with `TOFU_API=<mirror>` if needed.

## Scripts

```sh
# Latest version + suggested pin for a module (use before pinning any module)
scripts/tofu-module-latest.sh terraform-aws-modules/vpc/aws

# Provider versions (latest first)
scripts/tofu-provider-versions.sh hashicorp/aws

# List a provider's resources + datasources (latest version by default)
scripts/tofu-provider-docs.sh hashicorp/aws

# Fetch one resource's doc (markdown). Third arg pins a version; default is latest.
scripts/tofu-provider-docs.sh hashicorp/aws aws_instance
scripts/tofu-provider-docs.sh hashicorp/aws aws_instance v6.53.0

# Fetch a datasource doc: pass --kind datasource as the 4th arg
scripts/tofu-provider-docs.sh hashicorp/aws aws_ami "" --kind datasource

# Search modules
scripts/tofu-module-search.sh vpc
```

The `aws_instance` -> doc mapping strips the `aws_` prefix (`aws_instance` -> `instance`). If
that heuristic misses, list docs first and match the exact `name` from the version index.

## API cheat sheet (for one-off jq)

Base: `https://api.opentofu.org`. Version ids carry a `v` prefix (`v6.53.0`). `{kind}` is
`resource|datasource|function|guide`; the URL segment is plural (`resources`).

| Path | Returns |
|---|---|
| `/registry/docs/providers/{ns}/{name}/index.json` | provider + `.versions[].id` (newest first) |
| `/registry/docs/providers/{ns}/{name}/{ver}/index.json` | `.docs.resources[]`, `.docs.datasources[]` ({name,title,...}) |
| `/registry/docs/providers/{ns}/{name}/{ver}/resources/{doc}.md` | one resource doc (markdown) |
| `/registry/docs/modules/{ns}/{name}/{target}/index.json` | module + `.versions[].id` |
| `/registry/docs/modules/{ns}/{name}/{target}/{ver}/index.json` | `.variables{}`, `.outputs{}`, `.dependencies[]`, `.resources[]` |
| `/registry/docs/modules/{ns}/{name}/{target}/{ver}/README.md` | module README |
| `/registry/docs/search?q=<urlenc>` | search array; each item `.type` in module/provider/resource/datasource, `.link_variables{}` |
| `/top/providers?limit=N` | top providers by popularity |

Examples:
```sh
B=https://api.opentofu.org
curl -s "$B/registry/docs/providers/hashicorp/aws/v6.53.0/index.json" \
  | jq -r '.docs.resources[] | "\(.name)\t\(.title)"'
curl -s "$B/registry/docs/modules/terraform-aws-modules/vpc/aws/index.json" | jq -r '.versions[0].id'
curl -s "$B/registry/docs/search?q=$(printf %s vpc | jq -sRr @uri)" | jq '.[0]'
```

`ModuleVersion` fields worth knowing for wiring a module:
`.variables{<name>:{type,default,description,required,sensitive}}`, `.outputs{<name>:{...}}`,
`.providers[]`, `.dependencies[]`, `.resources[]`, `.submodules{}`, `.examples{}`.

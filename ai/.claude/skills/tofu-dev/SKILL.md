---
name: tofu-dev
description: Use when writing, reviewing, refactoring, or debugging OpenTofu (tofu) infrastructure for AWS - modules, environments, state/backends, providers, IAM, mock tests, or the validate gate. Enforces one opinionated AWS+OpenTofu ruleset so every project looks the same. Activate when the user says "write a tofu module", "add an AWS resource in tofu", "set up opentofu for AWS", "structure my tofu project", "add remote state", "write a tofu mock test", "validate my tofu", "add a terraform-aws-modules module", "migrate this to opentofu", or edits files under tofu/ (*.tf, *.tofu, *.hcl, *.tofutest.hcl, *.tfvars). Do not use for CloudFormation, CDK, Pulumi, raw AWS CLI/console work, or Kubernetes manifests.
---

# OpenTofu on AWS

One opinionated ruleset for AWS infrastructure written in OpenTofu. The goal is that every
project we touch has the **same** layout, naming, state model, testing, and validate gate.
This skill is procedural: **diagnose, look up real schemas, then generate** - do not write
resources from memory.

Only `tofu` (never `terraform`), only AWS, only **mock testing**. OpenTofu floor is 1.8
(`mock_provider`); native S3 lockfile needs 1.10+.

## Response contract

Every non-trivial answer follows this shape:

1. **Assumptions & version floor** - tofu/provider/module versions you target.
2. **Which rule applies** - name the convention or reference section.
3. **The change + tradeoffs** - the HCL, and what you chose against.
4. **Validation plan** - the exact commands (`scripts/validate-tofu.sh`, `tofu test`).
5. **Rollback notes** - `moved {}` blocks, state implications, anything destructive.

## Diagnose before you generate

Route to the right reference instead of loading everything:

| The task / symptom | Load |
|---|---|
| Layout, naming, tags, variables, IAM, secrets, state, providers | `references/conventions.md` |
| "Is there a premade module for X?", picking/pinning modules | `references/aws-modules.md` |
| Writing/running tests, mocks, assertions | `references/testing.md` |
| Need a resource/module's real attributes before writing | `references/registry-lookup.md` |
| Security scan findings, IAM/SG/KMS/S3/state hardening | `references/security.md` |

## Core workflow

1. **Check for a premade module first.** For any non-trivial building block (VPC, ALB, RDS,
   ECS, S3, IAM, security groups, CDN, certs, queues), prefer a `terraform-aws-modules/*`
   module over hand-rolled `aws_*` resources. See `references/aws-modules.md`. Only hand-roll
   for trivial single primitives or when the module can't express what's needed - and say why.
2. **Look up real schemas** before writing resources or test assertions. Use the registry
   scripts in `scripts/` (see `references/registry-lookup.md`) so attributes and nested-block
   shapes (set vs list vs computed) are correct, not guessed.
3. **Follow the conventions** in `references/conventions.md` - two-tier layout (environments
   wire modules; modules hold resources), file split, `locals { name, tags }`, `snake_case`
   typed+described variables, `jsonencode` IAM policies, S3 native-lockfile state.
4. **Write mock tests** for new module logic. Mock-only, `.tofutest.hcl`, `mock_provider`.
   See `references/testing.md`. Scaffold from `assets/module-template/`.
5. **Run the gate**: `scripts/validate-tofu.sh <tofu-root>` - terraform-docs, `tofu fmt`,
   tflint, trivy, `tofu test`, `tofu validate`. It fails fast if any CLI tool is missing.

## Key rules (summary; details in references)

- **`tofu`, not `terraform`.** Commands, docs, and the CLI are OpenTofu.
- **Prefer `terraform-aws-modules/*`** with a pessimistic pin (`version = "~> <MAJOR>.0"`).
  Never hardcode a remembered version - resolve the current major with
  `scripts/tofu-module-latest.sh <source>` every time, since majors move fast.
- **Two tiers.** `environment/<env>/` are root modules that only wire child modules + set
  providers/backend. `modules/<concern>/` hold the `aws_*` resources, referenced by relative
  path, reused across envs.
- **State**: partial S3 backend, native lockfile (`use_lockfile = true`), no DynamoDB. One
  bucket, per-env state key. No tofu workspaces - one directory per env.
- **Providers only in the env root**; child modules declare `required_providers` in
  `versions.tf` but never a `provider` block. Env root sets `default_tags`.
- **Naming/tags**: every module opens `main.tf` with `locals { name, tags }`; primary
  resource labeled `this`; per-resource `Name` via `merge(local.tags, {...})`.
- **IAM** with `jsonencode(...)`, not `aws_iam_policy_document` data sources. Least privilege.
- **Testing is mock-only.** No real providers, no cloud, no Terratest. Mocks validate HCL
  logic, not that it would actually deploy - keep that in mind.
- **Security**: never suppress a trivy finding inline - use `.trivyignore.yaml` with a written
  justification. Secrets never in variable defaults or committed tfvars.

## Scripts

- `scripts/validate-tofu.sh [tofu-root]` - the full validate gate, fail-fast on missing tools.
- `scripts/tofu-module-latest.sh <ns/name/target>` - latest version + `~>` pin for a module.
- `scripts/tofu-module-search.sh <query>` - search the registry for modules.
- `scripts/tofu-provider-versions.sh <ns/name>` - e.g. `hashicorp/aws`, list versions.
- `scripts/tofu-provider-docs.sh <ns/name> [resource] [version]` - list or fetch resource docs.

Registry scripts hit `api.opentofu.org` (cheaper than an MCP) and fail fast if curl/jq missing.

## Assets

`assets/module-template/` - a starter child module (`main.tf`, `variables.tf`, `outputs.tf`,
`versions.tf`) plus `tests/example.tofutest.hcl`. Copy it when scaffolding a new module.

## Don't

- Don't write `terraform` (use `tofu`), a DynamoDB lock table (native lockfile), or tofu
  workspaces (one dir per env).
- Don't put a `provider` or backend/`required_version` block in a child module.
- Don't hand-roll a resource when a maintained `terraform-aws-modules` module fits.
- Don't write tests against real providers or the cloud - mock only.
- Don't suppress trivy inline or commit real `*.tfvars`.
- Don't guess resource attributes - look them up first.

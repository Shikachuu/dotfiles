# AWS + OpenTofu conventions

How the tofu is written. Opinionated and identical across projects. Baseline is our ECS
Fargate template, generalized here - keep the topology in the project's own docs, not here.

## Layout

Two tiers. **Environments** are root modules that only _wire child modules together_ (plus
glue: providers, backend, account-level IAM). **Modules** hold all the `aws_*` resources and
are reused across environments with per-env variable overrides.

```
tofu/
├── .tflint.hcl              # lint config (tags rule + aws ruleset + recommended preset)
├── .trivyignore.yaml        # security-scan suppressions, each with a justification
├── .gitignore
├── environment/             # ROOT modules - one dir per state/env, wiring only
│   ├── global/              # account-wide, region-agnostic: ECR, GitHub OIDC deploy role
│   ├── stg/                 # staging
│   └── prd/                 # production (three letters: prd/stg)
└── modules/                 # CHILD modules - reusable, one per concern
    └── vpc/ alb/ ecs/ rds/ s3/ iam/ secrets/ acm/ ...
```

- No tofu **workspaces** - each env is its own directory with its own state key.
- Child modules referenced by relative path: `source = "../../modules/vpc"`.
- One module per concern. Encode variants (spot vs on-demand, singleton scheduler) as module
  **inputs**, not separate modules.
- Use `moved {}` blocks for refactors (renaming a module/resource) instead of destroy+recreate.

### File split per module

Every module (and env root) has the canonical trio plus `versions.tf`:

- `main.tf` - a `locals` block (name + tags) at the top, then the primary resource(s).
- `variables.tf` - all inputs.
- `outputs.tf` - all outputs.
- `versions.tf` - the `terraform {}` block (`required_version` + `required_providers`).

Start splitting when `main.tf` outgrows ~250 lines. Split into files **named after what they
contain** (`iam.tf`, `alb.tf`, `acm.tf`), never `main-2.tf`. No `providers.tf` or `locals.tf`
files - providers live in the env root's `main.tf`; `locals` live inline at the top of `main.tf`.

## State

Partial S3 backend, hardcoded per environment, with the **native S3 lockfile** - no DynamoDB
table. One shared state bucket; the **key is the per-env differentiator**.

```hcl
terraform {
  backend "s3" {
    use_lockfile = true
    region       = "eu-central-1"
    key          = "stg/terraform.tfstate"   # global/... , prd/... for the others
    bucket       = "terraform-state-<account-id>-<region>"
  }
}
```

`.gitignore` keeps `.terraform.lock.hcl` committed and ignores `*.tfstate*`, `.terraform/`,
and `*.tfvars` except `example.tfvars`.

## Providers & versions

Providers are declared **only in the env root `main.tf`**. Child modules declare
`required_providers` in `versions.tf` but **never** a `provider` block. The env root sets
`default_tags` so every resource is tagged without per-resource effort:

```hcl
provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      ManagedBy   = "opentofu"
      Environment = var.environment
      Project     = var.project_name
    }
  }
}
```

Version pinning:

- Env `required_version` pinned **exactly** to the pinned tofu (e.g. `= "1.12.3"`); child
  modules use a floor (`>= 1.12.0`) so they stay reusable. OpenTofu floor is 1.8 for
  `mock_provider`, 1.10 for the native S3 lockfile.
- Providers use pessimistic `~>` (`aws = "~> <MAJOR>.0"`). Resolve `<MAJOR>` from
  `scripts/tofu-provider-versions.sh hashicorp/aws` - don't hardcode a remembered version.
- No provider aliasing when it's a single account + single region. Add a `us-east-1` alias
  only when something genuinely requires it (e.g. CloudFront/ACM in us-east-1).

## Naming & tags

Every child module opens `main.tf` with this exact pattern:

```hcl
locals {
  name = "${var.project_name}-${var.environment}"          # myproj-stg
  tags = merge(var.tags, {
    ManagedBy   = "opentofu"
    Environment = var.environment
  })
}
```

- Resource names are `${local.name}-<role>` -> `myproj-stg-rds`, `myproj-prd-alb`.
- The module re-applies `ManagedBy`/`Environment` on purpose (belt-and-suspenders - the module
  stays correct even without the `default_tags` provider). Per-resource, add `Name` by merging:
  `tags = merge(local.tags, { Name = "${local.name}-rds" })`.
- tflint enforces `ManagedBy` + `Environment` on every taggable resource
  (`aws_resource_missing_tags`); a missing tag fails the gate.
- **Resource block labels**: the module's primary resource is labeled `this`
  (`aws_db_instance.this`); secondaries get descriptive labels (`aws_security_group.rds`).
  Reserve `this` for genuine singletons.
- Prefer **context-prefixed** variable names: `vpc_cidr_block`, not `cidr`.

## Variables

- `snake_case`, every variable has an explicit `type` and a `description`.
- A `tags` input on every module: `variable "tags" { type = map(string); default = {} }`,
  merged via `local.tags`.
- Use `validation {}` blocks for enum-like inputs. Prefer `optional()` with typed defaults
  over `map(any)`/`any`.
- `sensitive = true` for secrets - but note this only masks display; the value still lives in
  state (see `references/security.md`).
- Bool/number flags default sensibly per environment intent (e.g. `multi_az = false` for stg).

## Outputs

- Always a `description`; mark `sensitive` where needed.
- Expose stable subsets, not whole provider objects. Return objects for related values.
- Naming: `{name}_{type}_{attribute}`, plural for lists (`private_subnet_ids`).

## IAM & patterns

- Write IAM policies with `jsonencode({ Version = "2012-10-17", Statement = [...] })` - not
  `aws_iam_policy_document` data sources.
- Apps on ECS get AWS access via **ECS task roles** (this is ECS, not EKS - no IRSA). The
  account-level GitHub Actions OIDC provider + deploy role live in `environment/global`.
- Fan out with `for_each = toset(var.service_names)` rather than copy-pasted blocks.
- Guard rotated/placeholder secrets with `lifecycle { ignore_changes = [secret_string] }`;
  use `create_before_destroy` on ACM certs.

## Secrets

All config for a service lives in **one Secrets Manager secret per environment** (a JSON
blob), referenced from the ECS task definition's `secrets[]` array. Name secrets
`<env>/<service>/<purpose>` (e.g. `stg/mobile/config`). The task role grants read on
`arn:...:secret:${environment}/*`.

## Validate gate

`scripts/validate-tofu.sh <tofu-root>` runs, in order:

1. **terraform-docs** - regenerates each env's `README.md` (injected) and `example.tfvars`.
2. **tofu fmt** - `tofu fmt -check -recursive`; fix with `tofu fmt -recursive`.
3. **tflint** - `--recursive --minimum-failure-severity=warning` (AWS ruleset + `recommended`).
4. **trivy** - `fs --scanners secret,misconfig,vuln`, exit 1 on any finding.
5. **tofu test** - runs any discovered `*.tofutest.hcl`/`*.tftest.hcl` (mock tests).
6. **tofu validate** - per environment, with `tofu init -backend=false` (no creds/state needed).

Security exceptions go in `.trivyignore.yaml` only, each keyed by AVD id with a written
`statement:` justification - never inline-suppress or disable a scanner.

## Deploy

Deploys run manually via a `workflow_dispatch` GitHub Actions job (no plan-on-PR /
apply-on-merge). Auth is GitHub OIDC assuming the deploy role from `environment/global`. Each
env runs `tofu init -input=false` -> `plan` -> `apply -auto-approve`, `global` applied
**before** `stg`/`prd`, serialized under a non-cancellable concurrency group. PRs run the
validate gate.

## Don't

- Don't put a `provider` or `terraform` block in a child module.
- Don't add a DynamoDB lock table - native S3 lockfile (`use_lockfile = true`).
- Don't commit real `*.tfvars` - only generated `example.tfvars`.
- Don't reach for tofu workspaces - one directory + one state key per env.

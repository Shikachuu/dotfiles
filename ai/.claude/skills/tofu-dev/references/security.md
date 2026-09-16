# Security & compliance

AWS-only security rules. The validate gate runs `trivy fs --scanners secret,misconfig,vuln`.
Never suppress a finding inline - add it to `.trivyignore.yaml` keyed by AVD id with a written
`statement:` justification.

## Secrets

- **Never** put secrets in `variable` defaults or committed `*.tfvars`. Only `example.tfvars`
  (generated) is tracked.
- `sensitive = true` only **masks display** - the value still lives in state. For real
  exclusion from state, prefer:
  - `manage_master_user_password = true` (RDS) - AWS generates + stores in Secrets Manager.
  - write-only args (`*_wo`, TF 1.11+ / AWS provider v5.71+).
  - `ephemeral` resources/values (1.10+).
  - CI env injection.
- The `aws_secretsmanager_secret_version` **data source persists `secret_string` to state** -
  avoid reading secrets back through it.
- Store service config as one Secrets Manager secret per env (see the Secrets section of conventions.md);
  guard rotated values with `lifecycle { ignore_changes = [secret_string] }`.

## Security groups

- No `0.0.0.0/0` with `ip_protocol = "-1"` (all-ports open to the world).
- **No inline `ingress`/`egress` blocks** on `aws_security_group` - they recreate the SG on
  every change and conflict with rule resources. Use separate
  `aws_vpc_security_group_ingress_rule` / `_egress_rule` (AWS provider v5+), or the
  `terraform-aws-modules/security-group` module's `ingress_rules`/`egress_rules` maps.

## Encryption

- S3: explicit `aws_s3_bucket_server_side_encryption_configuration`. SSE-S3 (`AES256`) for
  general use; SSE-KMS with a CMB + rotation for regulated data (HIPAA/PCI/FedRAMP).
- Enable `bucket_key_enabled` with KMS to cut request costs.

## IAM

- Least privilege. Write policies with `jsonencode(...)`, never `Action = "*"` /
  `Resource = "*"`.
- Apps get access via ECS **task roles**, not long-lived keys. CI authenticates via the
  GitHub Actions OIDC provider + deploy role in `environment/global`.

## State hardening

The state bucket itself must be locked down:

- Versioning enabled.
- SSE-KMS with a CMK, `bucket_key_enabled = true`.
- `aws_s3_bucket_public_access_block` with all four flags `true`.
- A bucket policy with split `ListBucket` (bucket ARN) / object (`/*`) statements and a
  `DenyInsecureTransport` (TLS-enforcing) deny statement.
- Locking is the **native S3 lockfile** (`use_lockfile = true`) - no DynamoDB.

## Policy as code (optional)

For gated pipelines, run Conftest/OPA (Rego) against `terraform show -json tfplan`.
(`terraform-compliance` is archived - prefer Conftest/OPA.)

## LLM mistake checklist

- Wrote `terraform` instead of `tofu`.
- Hand-rolled a resource a `terraform-aws-modules` module already covers.
- Relied on `sensitive = true` to keep a secret out of state (it doesn't).
- Inline SG ingress/egress instead of rule resources / the module.
- `Action="*" Resource="*"` IAM policy.
- Suppressed a trivy finding inline instead of in `.trivyignore.yaml` with justification.
- Treated mock tests as proof the config deploys (they only check HCL logic).
- Guessed a resource attribute instead of looking it up.

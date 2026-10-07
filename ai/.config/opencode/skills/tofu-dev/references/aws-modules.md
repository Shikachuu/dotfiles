# Prefer premade AWS modules

Prefer official `terraform-aws-modules/*` community modules over hand-rolled `aws_*`
resources for any non-trivial building block (networking, load balancing, data stores,
compute, IAM, security groups, CDN, certs). Before writing raw resources, check whether a
module covers the concern (table below) and use it.

- Always source from the Terraform Registry with an explicit pessimistic version pin:
  `source = "terraform-aws-modules/<name>/aws"` and `version = "~> <MAJOR>.0"`.
- **Never hardcode a remembered version.** Get the current major from the lookup script every
  time (majors move fast - a wave recently bumped most modules to align with AWS provider v6).
  A version you recall may already be deprecated.
- Reach for IAM submodules with the `//modules/<name>` subdir syntax.
- Only hand-roll when: the resource is a single trivial primitive; the module hasn't exposed a
  needed argument or lags a new provider feature; the module's opinions conflict
  irreconcilably with requirements; or policy forbids external module dependencies - **and
  state the reason when you do.**
- Use a raw git `?ref=<tag>` source only for forks, unreleased commits, or air-gapped
  mirrors, never a branch.
- Commit `.terraform.lock.hcl`.

## Get the version before pinning (required)

```sh
scripts/tofu-module-latest.sh terraform-aws-modules/vpc/aws
# -> latest: v6.6.1
#    pin:    ~> 6.0
```

Use the printed `pin:` value for `version`. (Under the hood:
`curl -s https://api.opentofu.org/registry/docs/modules/terraform-aws-modules/vpc/aws/index.json | jq -r '.versions[0].id'`.)

## Concern -> module lookup

Source paths only - resolve the version with `scripts/tofu-module-latest.sh <source>`.

| Concern | Module source |
|---|---|
| VPC, subnets, NAT, routing | `terraform-aws-modules/vpc/aws` |
| Security group | `terraform-aws-modules/security-group/aws` |
| ALB / NLB + listeners/target groups | `terraform-aws-modules/alb/aws` |
| RDS instance | `terraform-aws-modules/rds/aws` |
| Aurora cluster | `terraform-aws-modules/rds-aurora/aws` |
| Kubernetes (EKS) | `terraform-aws-modules/eks/aws` |
| Containers (ECS/Fargate) | `terraform-aws-modules/ecs/aws` |
| Object storage (S3) | `terraform-aws-modules/s3-bucket/aws` |
| Serverless functions | `terraform-aws-modules/lambda/aws` |
| IAM roles/policies/IRSA | `terraform-aws-modules/iam/aws//modules/<sub>` |
| CDN | `terraform-aws-modules/cloudfront/aws` |
| TLS certs | `terraform-aws-modules/acm/aws` |
| Redis/Memcached | `terraform-aws-modules/elasticache/aws` |
| Secrets | `terraform-aws-modules/secrets-manager/aws` |
| Encryption keys | `terraform-aws-modules/kms/aws` |
| Queues | `terraform-aws-modules/sqs/aws` |
| Pub/sub | `terraform-aws-modules/sns/aws` |
| NoSQL table | `terraform-aws-modules/dynamodb-table/aws` |
| Container registry | `terraform-aws-modules/ecr/aws` |
| DNS | `terraform-aws-modules/route53/aws` |
| EC2 ASG / launch template | `terraform-aws-modules/autoscaling/aws` |
| Event routing | `terraform-aws-modules/eventbridge/aws` |
| HTTP/WS API gateway | `terraform-aws-modules/apigateway-v2/aws` |

IAM submodules (via `//modules/<name>`): `iam-role`, `iam-policy`, `iam-assumable-role`,
`iam-role-for-service-accounts` (IRSA), `iam-group`, `iam-user`, `iam-oidc-provider`,
`iam-read-only-policy`, `iam-account`.

## Minimal examples

Every `version` below is a placeholder - fill it from
`scripts/tofu-module-latest.sh <source>` before use. Do not copy a version literal.

VPC:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> <MAJOR>.0" # scripts/tofu-module-latest.sh terraform-aws-modules/vpc/aws

  name = local.name
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  tags               = local.tags
}
```

Security group (map syntax - no inline ingress/egress on raw resources):
```hcl
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> <MAJOR>.0" # scripts/tofu-module-latest.sh terraform-aws-modules/security-group/aws

  name   = "${local.name}-web"
  vpc_id = module.vpc.vpc_id

  ingress_rules = {
    https = { from_port = 443, ip_protocol = "tcp", cidr_ipv4 = "10.0.0.0/16" }
  }
  egress_rules = {
    all = { ip_protocol = "-1", cidr_ipv4 = "0.0.0.0/0" }
  }
  tags = local.tags
}
```

RDS (master password auto-managed via Secrets Manager by default - keeps it out of state):
```hcl
module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> <MAJOR>.0" # scripts/tofu-module-latest.sh terraform-aws-modules/rds/aws

  identifier        = "${local.name}-db"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.medium"
  allocated_storage = 20

  db_name  = "app"
  username = "app"
  port     = 5432
  # manage_master_user_password = true (default)
  tags = local.tags
}
```

ECS (integrated cluster + Fargate service):
```hcl
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> <MAJOR>.0" # scripts/tofu-module-latest.sh terraform-aws-modules/ecs/aws

  cluster_name               = local.name
  cluster_capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  services = {
    app = {
      cpu    = 1024
      memory = 2048
      container_definitions = {
        app = { cpu = 1024, memory = 2048, essential = true, image = "your-image:latest" }
      }
    }
  }
  tags = local.tags
}
```

S3 bucket:
```hcl
module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> <MAJOR>.0" # scripts/tofu-module-latest.sh terraform-aws-modules/s3-bucket/aws

  bucket = "${local.name}-assets"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  versioning               = { enabled = true }
  tags                     = local.tags
}
```

IAM role (submodule):
```hcl
module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "~> <MAJOR>.0" # scripts/tofu-module-latest.sh terraform-aws-modules/iam/aws

  name     = "${local.name}-task"
  policies = { ReadOnlyAccess = "arn:aws:iam::aws:policy/ReadOnlyAccess" }
}
```

Git source (only for forks/unreleased/air-gapped - pin a tag, never a branch):
```hcl
source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//.?ref=<tag>"
```

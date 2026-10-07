# Testing - mock only

We test **only** with the OpenTofu native test framework using mocked providers. No real
providers, no credentials, no cloud, no Terratest. Requires OpenTofu >= 1.8 (`mock_provider`).

**Know the limit:** mocks validate that your HCL logic and wiring are correct - they do NOT
prove the config would actually deploy against AWS. Keep that disclaimer in mind; do not treat
mock tests as integration coverage.

## Files & running

- Put tests in a `tests/` directory in the module (or next to the module).
- Use the OpenTofu-only extension **`.tofutest.hcl`** (also `.tofutest.json`). OpenTofu also
  reads `.tftest.hcl`, but when both `foo.tofutest.hcl` and `foo.tftest.hcl` exist it uses the
  `.tofutest.hcl` and ignores the other. Standardize on `.tofutest.hcl`.
- Run from the module root: `tofu test`. Useful: `tofu test -filter=tests/foo.tofutest.hcl`,
  `-verbose`. The validate gate discovers and runs these automatically.
- Look up real resource attributes before asserting (see `references/registry-lookup.md`) so
  assertions target attributes that exist, and so you handle set-vs-list-vs-computed correctly
  (a `set` nested block can't be indexed `[0]`; `list` can; `computed` values are apply-only).

## Anatomy of a test file

A file has: an optional file-level `variables`, one or more `mock_provider`/`override_*`
blocks, and one or more `run` blocks.

```hcl
variables {
  name = "test"          # file-level defaults for all runs
}

run "block_name" {
  command = plan         # plan | apply (default apply). plan is faster; apply materializes
                         # mocked computed attributes reliably.
  variables {
    name = "override"    # run-level override (highest precedence)
  }

  assert {
    condition     = aws_s3_bucket.this.bucket == "test-bucket"
    error_message = "bucket name did not match expected"
  }
}
```

- `assert.condition` can reference resources (`aws_s3_bucket.this.arn`), outputs
  (`output.name`), and prior runs (`run.block_name.output_name`).
- Variable precedence high->low: run block -> file -> CLI -> `.tfvars` -> env.

## mock_provider

`mock_provider` replaces an **entire** provider - it returns the real schema but auto-generates
fake values for all provider-computed attributes (IDs, ARNs), no creds, no API calls. Declare
one per provider the module uses.

```hcl
mock_provider "aws" {
  # alias           = "us_east_1"     # match a module's provider alias
  # override_during = plan            # plan | apply - when fake data is generated
  # source          = "./testing/aws" # load shared *.tfmock.hcl definitions

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn    = "arn:aws:s3:::my-test-bucket"
      region = "eu-central-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
}
```

- `mock_resource "TYPE" { defaults = {...} }` / `mock_data "TYPE" { defaults = {...} }` set
  specific computed attributes for every instance of that type; the rest auto-generate.
- Only pin the attributes your assertions depend on. Assert on **arguments you control**
  (`instance_type`, `tags["Name"]`), not auto-generated fake IDs.

## Override blocks (surgical)

Replace one resource/data/module. Placeable at file root or inside a `run` block.

```hcl
override_resource {
  target = aws_s3_bucket.example
  values = { arn = "arn:aws:s3:::bucket" }   # optional; auto-generated if omitted
}

override_data {
  target = data.aws_ami.this
  values = { id = "ami-0abcdef1234567890" }
}

override_module {
  target  = module.vpc
  outputs = { vpc_id = "vpc-mock123", private_subnets = ["subnet-a", "subnet-b"] }
}
```

- `override_resource`/`override_data` use `values`; `override_module` uses `outputs` (replaces
  the module's outputs wholesale - useful to mock a `terraform-aws-modules` dependency).
- Shareable mocks: put `mock_resource`/`mock_data`/override defs in `*.tfmock.hcl` and
  reference via `mock_provider "aws" { source = "./testing/aws" }`.

## Testing custom conditions

`expect_failures` asserts a checkable object fails - only for `validation` blocks, `check`
blocks, and output preconditions. Any other failure still fails the test.

```hcl
run "rejects_bad_input" {
  command = plan
  variables { instance_count = -1 }
  expect_failures = [var.instance_count]
}
```

## Minimal AWS template

See `assets/module-template/tests/example.tofutest.hcl` for a copy-ready starter.

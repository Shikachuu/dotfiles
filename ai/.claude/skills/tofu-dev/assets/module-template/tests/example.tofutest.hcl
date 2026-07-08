# Mock-only unit test. No real provider, no credentials, no cloud.
# Run: tofu test   (from the module root)

mock_provider "aws" {
  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::mock-bucket"
    }
  }
}

variables {
  project_name = "myproj"
  environment  = "stg"
}

run "bucket_name_follows_convention" {
  command = plan

  assert {
    condition     = aws_s3_bucket.this.bucket == "myproj-stg-example"
    error_message = "bucket name must be <project>-<env>-example"
  }
}

run "bucket_has_name_tag" {
  command = apply

  assert {
    condition     = aws_s3_bucket.this.tags["Name"] == "myproj-stg-example"
    error_message = "bucket must carry a Name tag matching its resource name"
  }
}

run "rejects_unknown_environment" {
  command = plan

  variables {
    environment = "dev"
  }

  expect_failures = [var.environment]
}

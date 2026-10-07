locals {
  name = "${var.project_name}-${var.environment}"
  tags = merge(var.tags, {
    ManagedBy   = "opentofu"
    Environment = var.environment
  })
}

# Primary resource is labeled `this`. Replace with a terraform-aws-modules module
# when one covers this concern (see references/aws-modules.md).
resource "aws_s3_bucket" "this" {
  bucket = "${local.name}-example"
  tags   = merge(local.tags, { Name = "${local.name}-example" })
}

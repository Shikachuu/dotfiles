# Child module: required_providers only, never a provider or backend block.
# Floor version so the module stays reusable; the env root pins exactly.
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Resolve <MAJOR> before init: scripts/tofu-provider-versions.sh hashicorp/aws
      version = "~> <MAJOR>.0"
    }
  }
}

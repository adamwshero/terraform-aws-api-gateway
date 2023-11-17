terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.30.0"
    }
    # Uncomment this lines below to generate the docs with the requirement
    # terragrunt = {
    #  source = "gruntworks/terragrunt"
    #  version = ">= 0.28.0"
    # }
  }
}

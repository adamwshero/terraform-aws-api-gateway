terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.5.0, < 5.75.0"
    }

    # Uncomment the lines below to generate the docs with the requirement
    # terraform-docs markdown table --output-file README.md --output-mode inject .
    #     terragrunt = {
    #      source = "gruntworks/terragrunt"
    #      version = ">= 0.28.0"
    #     }
  }
}

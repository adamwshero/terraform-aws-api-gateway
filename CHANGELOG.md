## 1.4.0 (May 19, 2025)

FEATURE:
  * Add base path mapping attribute for `aws_api_gateway_base_path_mapping` resource.
  * Add support for existing domains

CHORE:
  * Cleanup comments in main.tf
  * Reorganize base_path_mapping resources for readability.

## 1.3.0 (April 10, 2025)

FEATURE:
  * Supports many method settings & paths for each stage
  * Supports models
  * Add output for API Gateway domain name

CHORE:
  * Add tags to the API
  * Remove method path variable
  * Fix existing errors in examples & update examples

BUG:
  * Limit hashicorp/aws provider to `5.75.0` due to breaking changes using `5.76.0`
    * Error found for aws_api_gateway_stage: The argument "deployment_id" is required, but no definition was found.

## 1.2.0 (November 17, 2023)

FEATURE:
  * Supports custom domains for REGIONAL & EDGE endpoints
  * Supports optional resource policies

## 1.1.0 (November 10, 2023)

BUG:
  * Fixed issue invalid_index error for new deploys

## 1.0.8 (July 20, 2023)

CHORE:
  * Added sample architecture diagram for distributed model

## 1.3.0 (November 20, 2022)

BUG:
  * Fixed issue where canary couldn't be destroyed after being created.
  * Now we create the stage before it's destroyed.

FEATURE:
  * Added "Managed by Terraform" description to deployments.
  * Append "Deployed on {timestamp}" to stage descriptions.

CHORE:
  * Improved notes for the `aws_api_gateway_deployment` resource.
  * Updated README about `put_rest_api_mode` usage & known issues.

## 1.0.6 (November 1, 2022)

CHORE:
  * Removed Beta-Limited Support header from readme.

## 1.0.5 (November 1, 2022)

BUG:
  * Added option to disable canary given the current open issue.
  * Fixed usage plans and api key variables so the maps can be ommitted from input blocks if set to false.

CHORE:
  * Updated output descriptions for WAF and stage
  * Added examples for terraform and improved existing examples

## 1.0.4 (October 7, 2022)

BUG:

  * Fixed race condition with deployment vs stage under certain conditions.

## 1.0.3 (September 22, 2022)

CHORE:

  * Added all inputs/outputs in README
  * Set deployment to redeploy on timestamp
  * Removed unused variables
  * Updated example

## 1.0.2 (September 21, 2022)

CHORE:

  * Added support document links
  * Added special notes for merge mode
  * Expanded documentation on OpenAPI spec
  * Improved example

## 1.0.1 (September 19, 2022)

CHORE:

  * Improved README
  * Improved example

## 1.0.0 (September 17, 2022)

INITIAL:

  * Initial module creation
  * Updated README


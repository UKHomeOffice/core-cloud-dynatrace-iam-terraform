module "example" {
  source = "../"
  groups_and_permissions = {
    group_one = {
      group_description = "Group one description"
      attached_policies = {
        policy_static = {
          environment = "tvy38111"
        }
      }
    }
    group_two = {
      group_description = "Group two description"
      attached_policies = {
        policy_with_param = {
          environment = "tvy38111"
          policy_parameters = {
            zone = "zone1"
          }
          policy_metadata = {
            meta1 = "metaval1"
          }
        }
      }
    }
  }

  iam_policies = {
    policy_with_param = {
      policy_description = "My IAM policy_with_param description"
      policy_statement   = <<EOT
        ALLOW environment:roles:viewer, environment:roles:manage-settings
        WHERE environment:management-zone IN ("zone2", "$${bindParam:my-policy-param}");

        EOT
    }
    policy_static = {
      policy_description = "My IAM policy_static description"
      policy_statement   = <<EOT
        "ALLOW settings:objects:read;"

      EOT
    }
  }
  accountUUID = "a8c6fb99-cc30-46b5-9306-1111111"
}


terraform {
  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}

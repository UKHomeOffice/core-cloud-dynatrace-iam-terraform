module "example" {
  source = "../"
  groups_and_permissions = {
    autogroupasdtwo = {
      attached_policies = {
        anotherautomated = {    # Custom policy
          policy_parameters = { # Options parameters for the policy binding
            param1 = "value1"
          }
          policy_metadata = { # Options metadata for the policy binding
            meta1 = "metaval1"
          }
        }
      }
    }
    autogroupasd = {
      attached_policies = {
        anotherautomated = {    # Custom policy
          policy_parameters = { # Options parameters for the policy binding
            param1 = "value1"
          }
        }
      }
    }
  }

  iam_policies = {
    testpolicy = { # Created but unused     
      policy_permissions = [
        "settings:objects:read",
        "settings:schemas:read"
      ]
      policy_condition = "settings:schemaId = \"string\"" # Can be a complex condition - refer to Dynatrace documentation    
    }
    anotherautomated = {
      policy_permissions = [
        "settings:objects:read",
        "settings:schemas:read"
      ]
    }
  }

  accountUUID = "1111-1111-1111-1111-1111"
}


terraform {
  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}

# This file is shared(symlinked) between the root and the submodule(s)
# for DRY purpose
variable "groups_and_permissions" {
  type = map(object({
    # Refer to :
    #   https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_group#federated_attribute_values-1
    # and
    #   https://docs.dynatrace.com/docs/manage/identity-access-management/user-and-group-management/access-group-management
    # for more details
    federated_attribute_values = optional(list(string))
    # Refer to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy_bindings_v2 and
    # https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy
    # for more details.
    # Please note that 'environment' is deprecated from the 'iam_policy'
    # resource and therefore not supported here - only 'account' is supported
    # For documentation on parameters refer to:
    #   https://docs.dynatrace.com/docs/manage/identity-access-management/permission-management/manage-user-permissions-policies/advanced/iam-policy-templating
    environment_bound_policies = optional(map(object({
                          environment_id = string
                          policy_parameters = optional(map(string),null)
                          policy_metadata = optional(map(string),null)

    })),{})
    account_bound_policies = optional(map(object({
                          policy_parameters = optional(map(string),null)
                          policy_metadata = optional(map(string),null)

    })),{})

  }))
  description = "Map of IAM groups"
  default = {}
}

variable "accountUUID" {
  type = string
  description = "Root account UUID"
}
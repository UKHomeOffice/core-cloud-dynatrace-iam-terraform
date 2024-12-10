# This file is shared(symlinked) between the root and the submodule(s)
# for DRY purpose
variable "groups_and_permissions" {
  type = map(object({
    # Refer to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_group#permissions-1
    # and other relavant Dynatrace documentation for details
    # on providing inputs to the following variable
# !!! TODO - Dont use it until we require it !!!!!!!!!!
    permissions = optional(list(object({
                            name = string
                            scope = string
                            type = string
                          })),[])
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                        # Policies to be attached to the group
    # Refer to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy_bindings_v2 and
    # https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy
    # for more details.
    # Please note that 'environment' is deprecated from the 'iam_policy'
    # resource and therefore not supported here - only 'account' is supported
    # For documentation on parameters refer to:
    #   https://docs.dynatrace.com/docs/manage/identity-access-management/permission-management/manage-user-permissions-policies/advanced/iam-policy-templating
    attached_policies = optional(map(object({
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
# This file is shared(symlinked) between the root and the submodule(s)
# for DRY purpose
variable "groups_and_permissions" {
  type = map(object({
    # Refer to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_group#permissions-1
    # for details on providing inputs to the following variable
    # According to the above documentation, there must be a max of onlyone
    # permission to be provided
    permission = optional(object({
                            name = string
                            scope = string
                            type = string
                          }),null)
    # Policies to be attached to the group
    # Refer to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy_bindings_v2 and
    # https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy
    # for more details.
    # Please note that 'environment' is deprecated from the 'iam_policy'
    # resource and therefore not supported here - only 'account' is supported
    attached_policies = optional(map(object({
                          policy_parameters = optional(map(string),null)
                          policy_metadata = optional(map(string),null)

    })),{})
  }))
  description = "Map of IAM groups"
  default = {}
}

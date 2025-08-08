
variable "accountUUID" {
  type        = string
  description = "Root account UUID"
}


# Refer to https://docs.dynatrace.com/docs/manage/identity-access-management/permission-management/manage-user-permissions-policies/advanced/iam-policystatements
variable "iam_policies" {
  type = map(object({
    policy_statement   = string
    policy_description = string
  }))
  description = "Map of policy names and their policy query statement."
}


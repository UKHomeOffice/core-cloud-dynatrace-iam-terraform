# !!!! There is one more variable definition in the file 
# 'iam_group_variable_type.tf' shared between the root and 
# the sub modules


# Refer to https://docs.dynatrace.com/docs/manage/identity-access-management/permission-management/manage-user-permissions-policies/advanced/iam-policystatements
variable "iam_policies" {
  type = map(object({
           policy_permissions = list(string) 
           policy_scope_account = optional(string,null)
           policy_condition = optional(string)
           policy_parameters = optional(map(string),{})
           policy_metadata   = optional(map(string),{})
         }))
  description = "Dictionary of policies."
  default = {}
}

variable "accountUUID" {
  type = string
  description = "Root account UUID"
}
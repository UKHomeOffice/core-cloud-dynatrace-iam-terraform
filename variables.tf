# !!!! There are more variable definitions in the file 
# 'shared_vars.tf' shared between the root and 
# the sub modules


# Refer to https://docs.dynatrace.com/docs/manage/identity-access-management/permission-management/manage-user-permissions-policies/advanced/iam-policystatements
variable "iam_policies" {
  type = map(object({
           policy_permissions = list(string) 
           policy_condition = optional(string)
           policy_parameters = optional(map(string),{})
           policy_metadata   = optional(map(string),{})
         }))
  description = "Dictionary of policies."
  default = {}
}

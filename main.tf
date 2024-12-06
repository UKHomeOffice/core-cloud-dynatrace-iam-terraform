# Required when creating the groups so we can attach newly created
# and/or existing policies
data "dynatrace_iam_policies" "allPolicies" {
  environments = ["*"]
  accounts     = ["*"]
  global       = true
}

resource "dynatrace_iam_policy" "env_policy" {
  for_each = var.iam_policies

  name            = each.key
  account         = var.accountUUID # Account, until discovered to be otherwise, account id is going to be a constant
  statement_query = "ALLOW ${join(", ",each.value.policy_permissions)} ${coalesce(each.value.policy_condition, "__UNDEFINED__") != "__UNDEFINED__" ? format("%s %s","WHERE",each.value.policy_condition) : "" };"
}

module "groups_and_bindings" {
  source = "./groups_and_bindings"
  for_each = var.groups_and_permissions

  groups_and_permissions= tomap({"${each.key}"=each.value})
  # Concatenate the newly created policies with the existing polices
  # so we can refer to the policies both during plan and apply stages
  group_policies = concat(data.dynatrace_iam_policies.allPolicies.policies, [for k, v in dynatrace_iam_policy.env_policy : v])
}

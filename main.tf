resource "dynatrace_iam_policy" "env_policy" {
  for_each = var.iam_policies

  name            = each.key
  account         = var.accountUUID
  statement_query = each.value
}

module "groups_and_bindings" {
  source   = "./groups_and_bindings"
  for_each = var.groups_and_permissions

  group_name                 = each.key
  attached_policies          = each.value.attached_policies
  federated_attribute_values = each.value.federated_attribute_values
  all_policies               = [for k, v in dynatrace_iam_policy.env_policy : v]
}

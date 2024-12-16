locals {
  group_name = keys(var.groups_and_permissions)[0]
}

resource "dynatrace_iam_group" "cc-iam-group" {
  name          = local.group_name
  federated_attribute_values = toset(var.groups_and_permissions[local.group_name].federated_attribute_values)
}

resource "dynatrace_iam_policy_bindings_v2" "cc-acc-policy-bindings" {
  group = dynatrace_iam_group.cc-iam-group.id
  account = var.accountUUID
  dynamic "policy" {
    for_each = keys(var.groups_and_permissions[local.group_name].account_bound_policies)
    content {
      id = element([for item in var.group_policies : item if item["name"] == policy.value], 0).id
      parameters = var.groups_and_permissions[local.group_name].account_bound_policies[policy.value].policy_parameters
      metadata = var.groups_and_permissions[local.group_name].account_bound_policies[policy.value].policy_metadata
    }
  }
}

module "environment_policies" {
  source = "./environment_policies"
  for_each = var.groups_and_permissions[local.group_name].environment_bound_policies

  group_id = dynatrace_iam_group.cc-iam-group.id
  env_id = each.value.environment_id
  policy_id = element([for item in var.group_policies : item if item["name"] == each.key], 0).id
  policy_parameters = each.value.policy_parameters
  policy_metadata = each.value.policy_metadata
}

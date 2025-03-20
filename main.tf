data "dynatrace_iam_policies" "allPolicies" {
  environments = ["*"]
  accounts     = ["*"]
  global       = true
}

resource "dynatrace_iam_policy" "env_policy" {
  for_each = var.iam_policies

  name            = each.key
  description     = each.value.policy_description
  account         = var.accountUUID
  statement_query = each.value.policy_statement
}

resource "dynatrace_iam_policy_boundary" "boundaries" {
  for_each = var.iam_boundary_policies

  name  = each.key
  query = each.value.policy_query

}

locals {
  groups_helper = flatten([
    for group_name, group_values in var.groups_and_permissions :
    flatten([
      for policy_name, policy_values in group_values.attached_policies :
      flatten([
        for env_id, env_params in policy_values : {
          "group_name"                 = group_name
          "policy_name"                = policy_name
          "group_description"          = group_values.group_description
          "federated_attribute_values" = group_values.federated_attribute_values
          "env_id"                     = env_id
          "env_params"                 = env_params
        }
      ])
    ])
  ])
  iam_policies = concat(data.dynatrace_iam_policies.allPolicies.policies, [for k, v in dynatrace_iam_policy.env_policy : v])
}

resource "dynatrace_iam_group" "cc-iam-group" {
  for_each = var.groups_and_permissions

  name                       = each.key
  description                = each.value.group_description
  federated_attribute_values = each.value.federated_attribute_values
}

resource "dynatrace_iam_policy_bindings_v2" "cc-policy-bindings" {
  for_each = tomap({
    for group_permission in local.groups_helper : "${group_permission.group_name}.${group_permission.policy_name}.${group_permission.env_id}" => group_permission
  })

  group = element([for item in dynatrace_iam_group.cc-iam-group : item if item["name"] == each.value.group_name], 0).id

  environment = each.value.env_id

  policy {
    id         = element([for item in local.iam_policies : item if item["name"] == each.value.policy_name], 0).id
    parameters = each.value.env_params != null ? each.value.env_params.policy_parameters : null
    metadata   = each.value.env_params != null ? each.value.env_params.policy_metadata : null
    boundaries = [for item in dynatrace_iam_policy_boundary.boundaries : item.id if item["name"] == each.value.group_name ]
  }
}

# ---------------------------------------------
# Data block to fetch all policies
# ---------------------------------------------
data "dynatrace_iam_policies" "allPolicies" {
  environments = ["*"]
  accounts     = ["*"]
  global       = true
}

# ---------------------------------------------
# Create policies from var.iam_policies
# ---------------------------------------------
resource "dynatrace_iam_policy" "env_policy" {
  for_each = var.iam_policies

  name            = each.key
  description     = each.value.policy_description
  account         = var.accountUUID
  statement_query = each.value.policy_statement
}

# ---------------------------------------------
# Local variables to group policies
# ---------------------------------------------
locals {
  # Flatten with OLD key format (group.policy.env)
  permission_helper = merge(flatten([
    for group_name, group_values in var.groups_and_permissions :
    flatten([
      for policy_name, policy_values in group_values.attached_policies :
      {
        for env_id, env_params in policy_values :
        "${group_name}.${policy_name}.${env_id}" => {
          group_name                 = group_name
          policy_name                = policy_name
          group_description          = group_values.group_description
          federated_attribute_values = group_values.federated_attribute_values
          env_id                     = env_id
          env_params                 = env_params
        }
      }
    ])
  ])...)

  # Group by group_name + env_id to collect policies
  grouped_permission_helper = {
    for group_env_key, permission_list in {
      for permission_key, permission_value in local.permission_helper :
      "${permission_value.group_name}.${permission_value.env_id}" => permission_value...
    } :
    group_env_key => {
      group_name   = permission_list[0].group_name
      env_id       = permission_list[0].env_id
      env_params   = permission_list[0].env_params
      policy_names = [for p in permission_list : p.policy_name]
    }
  }

  # Policy IDs from env_policy
  policy_ids = {
    for p in dynatrace_iam_policy.env_policy : 
    p.name => p.id
  }
}

# ---------------------------------------------
# Create policy boundaries (restored as before)
# ---------------------------------------------
resource "dynatrace_iam_policy_boundary" "boundaries" {
  for_each = {
    for k, v in local.permission_helper : 
    k => v.env_params.policy_boundary 
    if v.env_params.policy_boundary != null
  }

  name  = each.key
  query = each.value
}

# ---------------------------------------------
# Create policy bindings (sorted policies to avoid recreate)
# ---------------------------------------------
resource "dynatrace_iam_policy_bindings_v2" "cc_policy_bindings" {
  for_each = local.grouped_permission_helper

  group       = element(
    [for g in dynatrace_iam_group.cc_iam_group : g.id if g.name == each.value.group_name],
    0
  )
  environment = each.value.env_id

  dynamic "policy" {
    # Sort policy list for stable ordering
    for_each = sort(each.value.policy_names)
    content {
      id = local.policy_ids[policy.value]
    }
  }
}

# ---------------------------------------------
# Dynatrace IAM groups
# ---------------------------------------------
resource "dynatrace_iam_group" "cc_iam_group" {
  for_each = {
    for group_name, group_values in var.groups_and_permissions :
    group_name => {
      description                = group_values.group_description
      federated_attribute_values = group_values.federated_attribute_values
    }
  }

  name                       = each.key
  description                = each.value.description
  federated_attribute_values = each.value.federated_attribute_values
}

# ---------------------------------------------
# Debug outputs
# ---------------------------------------------
output "permission_helper" {
  value = local.permission_helper
}

output "policy_name_id_map" {
  value = local.policy_ids
}

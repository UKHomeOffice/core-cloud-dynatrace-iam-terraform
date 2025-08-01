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

# locals {
#   permission_helper = merge(flatten([
#     for group_name, group_values in var.groups_and_permissions :
#     flatten([
#       for policy_name, policy_values in group_values.attached_policies :
#       {
#         for env_id, env_params in policy_values : "${group_name}.${policy_name}.${env_id}" =>
#         {
#           "group_name"                 = group_name
#           "policy_name"                = policy_name
#           "group_description"          = group_values.group_description
#           "federated_attribute_values" = group_values.federated_attribute_values
#           "env_id"                     = env_id
#           "env_params"                 = env_params
#         }
#       }
#     ])
#   ])...)

#   iam_policies = concat(data.dynatrace_iam_policies.allPolicies.policies, [for k, v in dynatrace_iam_policy.env_policy : v])
# }
locals {
  # ---------------------------------------------
  # Step 1: Build permission_helper
  # ---------------------------------------------
  # This flattens var.groups_and_permissions into a flat map where:
  #   key   = "<group_name>.<policy_name>.<env_id>"
  #   value = object containing all relevant attributes for the binding
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

  # ---------------------------------------------
  # Step 2: Group permission_helper by group_name + env_id
  # ---------------------------------------------
  # Purpose: Prevent multiple policy bindings from overwriting each other
  grouped_permission_helper = {
    for group_env_key, permission_list in {
      for permission_key, permission_value in local.permission_helper :
      # Group by the key <group_name>-<env_id>
      "${permission_value.group_name}-${permission_value.env_id}" => permission_value...
    } :
    group_env_key => {
      group_name   = permission_list[0].group_name
      env_id       = permission_list[0].env_id
      env_params   = permission_list[0].env_params
      # Collect policy names from the grouped items
      policy_names = [for p in permission_list : p.policy_name]
    }
  }
}


resource "dynatrace_iam_group" "cc_iam_group" {
  for_each = var.groups_and_permissions

  name                       = each.key
  description                = each.value.group_description
  federated_attribute_values = each.value.federated_attribute_values
}


resource "dynatrace_iam_policy_boundary" "boundaries" {
  for_each = {
    for k, v in local.permission_helper : k => v.env_params.policy_boundary if v.env_params.policy_boundary != null
  }

  name  = each.key
  query = each.value

}

resource "dynatrace_iam_policy_bindings_v2" "cc_policy_bindings" {
  for_each = local.grouped_permission_helper

  # ---------------------------------------------
  # Validate group existence before binding
  # ---------------------------------------------
  group = element(
    sort([
      for group_resource in dynatrace_iam_group.cc_iam_group :
      group_resource.id
      if group_resource.name == each.value.group_name
    ]),
    0,
    null
  )

  # Handle missing group with an error message if no group is found
  lifecycle {
    precondition {
      condition     = group != null
      error_message = "Group '${each.value.group_name}' does not exist in dynatrace_iam_group.cc_iam_group"
    }
  }

  environment = each.value.env_id

  # ---------------------------------------------
  # Policy Binding
  # ---------------------------------------------
  dynamic "policy" {
    for_each = [
      for policy_name in each.value.policy_names :
      {
        policy_id = element(
          sort([
            for policy_resource in dynatrace_iam_policy.env_policy :
            policy_resource.id
            if policy_resource.name == policy_name
          ]),
          0,
          null
        )
      }
    ]

    content {
      id         = policy.value.policy_id
      parameters = each.value.env_params != null ? each.value.env_params.policy_parameters : null
      metadata   = each.value.env_params != null ? each.value.env_params.policy_metadata : null

      # ---------------------------------------------
      # Validate boundaries existence before binding
      # ---------------------------------------------
      boundaries = sort([
        for boundary_item in dynatrace_iam_policy_boundary.boundaries :
        boundary_item.id
        if boundary_item.name == each.key
      ])
    }
  }
}



output "permission_helper" {
  value = local.permission_helper
}

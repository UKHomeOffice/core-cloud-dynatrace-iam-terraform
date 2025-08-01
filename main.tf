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
  # Step 1: Define static mapping of policy names to IDs
  # ---------------------------------------------
  policy_ids = {
    "CC-Standard-Policy"         = "08163e58-299a-485f-ac14-33a703938afa#-#account#-#dbc44ee4-8095-4c36-b335-2606b60e1601"
    "CC-Logs-Viewer-Policy"      = "085ab1ef-943b-4c40-8af1-ea39710a2887#-#account#-#dbc44ee4-8095-4c36-b335-2606b60e1601"
    "CC-Data-Viewer-Policy"      = "88507f89-64cb-4702-8be4-3ce2715c522f#-#account#-#dbc44ee4-8095-4c36-b335-2606b60e1601"
    "CC-Advanced-Policy"         = "984c88c9-e305-4774-82a0-23ffdec8b0cb#-#account#-#dbc44ee4-8095-4c36-b335-2606b60e1601"
    "CC-Settings-Writer-Policy"  = "b546cd4d-97aa-4ba0-8c83-973cd0a47d00#-#account#-#dbc44ee4-8095-4c36-b335-2606b60e1601"
    "CC-Admin-User"              = "f2b634e3-5770-4e61-9862-8f62e1a32838#-#account#-#dbc44ee4-8095-4c36-b335-2606b60e1601"
  }

  # ---------------------------------------------
  # Step 2: Build permission_helper
  # ---------------------------------------------
  # Flattens var.groups_and_permissions into a flat map where:
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
  # Step 3: Group permission_helper by group_name + env_id
  # ---------------------------------------------
  # Prevents overwrites when multiple policies are attached to the same group/env
  grouped_permission_helper = {
    for group_env_key, permission_list in {
      for permission_key, permission_value in local.permission_helper :
      "${permission_value.group_name}-${permission_value.env_id}" => permission_value...
    } :
    group_env_key => {
      group_name   = permission_list[0].group_name
      env_id       = permission_list[0].env_id
      env_params   = permission_list[0].env_params
      policy_names = [for p in permission_list : p.policy_name]
    }
  }
}

# --------------------------------------------------
# Dynatrace IAM Group
# --------------------------------------------------
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




resource "dynatrace_iam_policy_boundary" "boundaries" {
  for_each = {
    for k, v in local.permission_helper : k => v.env_params.policy_boundary if v.env_params.policy_boundary != null
  }

  name  = each.key
  query = each.value

}

resource "dynatrace_iam_policy_bindings_v2" "cc_policy_bindings" {
  for_each = local.permission_helper

  group       = dynatrace_iam_group.cc_iam_group[each.value.group_name].id
  environment = each.value.env_id

  policy {
    id         = local.policy_ids[each.value.policy_name]
    boundaries = []
  }
}


output "permission_helper" {
  value = local.permission_helper
}

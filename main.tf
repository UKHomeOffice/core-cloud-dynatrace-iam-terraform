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

locals {
  permission_helper = merge(flatten([
    for group_name, group_values in var.groups_and_permissions :
    flatten([
      for policy_name, policy_values in group_values.attached_policies :
      {
        for env_id, env_params in policy_values : "${group_name}.${policy_name}.${env_id}" =>
        {
          "group_name"                 = group_name
          "policy_name"                = policy_name
          "group_description"          = group_values.group_description
          "federated_attribute_values" = group_values.federated_attribute_values
          "env_id"                     = env_id
          "env_params"                 = env_params
        }
      }
    ])
  ])...)

  iam_policies = concat(data.dynatrace_iam_policies.allPolicies.policies, [for k, v in dynatrace_iam_policy.env_policy : v])
}

resource "dynatrace_iam_group" "cc-iam-group" {
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

# resource "dynatrace_iam_policy_bindings_v2" "cc-policy-bindings" {
#   for_each = local.permission_helper

#   # group = element([for item in dynatrace_iam_group.cc-iam-group : item if item["name"] == each.value.group_name], 0).id
#   group = try(element([for item in dynatrace_iam_group.cc-iam-group : item if item["name"] == each.value.group_name], 0).id, null)
  


#   environment = each.value.env_id

#   # policy {
#   #   # id         = element([for item in local.iam_policies : item if item["name"] == each.value.policy_name], 0).id
#   #   id      = try([for item in local.iam_policies : item if item["name"] == each.value.policy_name][0].id, null)
#   #   # parameters = each.value.env_params != null ? each.value.env_params.policy_parameters : null
#   #   # parameters = try(each.value.env_params.policy_parameters, null)
#   #   parameters = try(each.value.env_params != null ? each.value.env_params.policy_parameters : null, null)
#   #   # metadata   = each.value.env_params != null ? each.value.env_params.policy_metadata : null
#   #   # metadata   = try(each.value.env_params.policy_metadata, null)
#   #   metadata   = try(each.value.env_params != null ? each.value.env_params.policy_metadata : null, null)
#   #   # boundaries = [for item in dynatrace_iam_policy_boundary.boundaries : item.id if item.name == each.key]
#   #   boundaries = try([for item in dynatrace_iam_policy_boundary.boundaries : item.id if item.name == each.key], [])

#   # }
#   policy {
#     id         = element([for item in local.iam_policies : item if item["name"] == each.value.policy_name], 0).id
#     # parameters = each.value.env_params != null ? each.value.env_params.policy_parameters : {}
#     # metadata   = each.value.env_params != null ? each.value.env_params.policy_metadata : {}
#     boundaries = [for item in dynatrace_iam_policy_boundary.boundaries : item.id if item.name == each.key]
#   }

# }
resource "dynatrace_iam_policy_bindings_v2" "cc-policy-bindings" {
  for_each = local.permission_helper

  group       = try([for item in dynatrace_iam_group.cc-iam-group : item if item["name"] == each.value.group_name][0].id, "")
  environment = each.value.env_id

  policy {
    id         = try([for item in local.iam_policies : item if item["name"] == each.value.policy_name][0].id, "")
    parameters = try(each.value.env_params.policy_parameters, {})
    metadata   = try(each.value.env_params.policy_metadata, {})
    boundaries = try([for item in dynatrace_iam_policy_boundary.boundaries : item.id if item.name == each.key], [])
  }
}

output "permission_helper" {
  value = local.permission_helper
}

output "iam_policies" {
  value = local.iam_policies
}

output "policy_boundaries" {
  value = {
    for name, boundary in dynatrace_iam_policy_boundary.boundaries : 
    name => {
      name  = boundary.name
      query = boundary.query
    }
  }
}

output "env_params_by_key" {
  value = {
    for k, v in local.permission_helper : k => v.env_params
  }
}

output "cc_policy_bindings" {
  value = {
    for k, v in dynatrace_iam_policy_bindings_v2.cc-policy-bindings :
    k => {
      group       = v.group
      environment = v.environment
      policy = {
        id         = try(v.policy[0].id, "")
        parameters = try(v.policy[0].parameters, {})
        metadata   = try(v.policy[0].metadata, {})
        boundaries = try(v.policy[0].boundaries, [])
      }
    }
  }
}



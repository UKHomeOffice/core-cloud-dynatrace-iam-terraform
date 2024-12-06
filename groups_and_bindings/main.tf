terraform {
  required_providers {
    dynatrace = {
      version = "~> 1.0"
      source  = "dynatrace-oss/dynatrace"
    }
  }
}

locals {
  group_name = keys(var.groups_and_permissions)[0]
}

resource "dynatrace_iam_group" "cc-iam-group" {
  name          = local.group_name
  dynamic "permissions" {
    for_each = length(var.groups_and_permissions[local.group_name].permissions) > 0 ? [1] : []
    content {
      dynamic "permission" {
        for_each = var.groups_and_permissions[local.group_name].permissions
        content {
          name  = permission.value.name
          type  = permission.value.type
          scope = permission.value.scope
        }
      }
    }
  }
}

resource "dynatrace_iam_policy_bindings_v2" "cc-policy-bindings" {
  group = dynatrace_iam_group.cc-iam-group.id
  account = "6832d11c-2f40-4525-ac9e-f44cebc1cd76"
  dynamic "policy" {
    for_each = keys(var.groups_and_permissions[local.group_name].attached_policies)
    content {
      id = element([for item in var.group_policies : item if item["name"] == policy.value], 0).id
      parameters = var.groups_and_permissions[local.group_name].attached_policies[policy.value].policy_parameters
      metadata = var.groups_and_permissions[local.group_name].attached_policies[policy.value].policy_metadata
    }
  }
}

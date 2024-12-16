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
  federated_attribute_values = toset(var.groups_and_permissions[local.group_name].federated_attribute_values)
}

resource "dynatrace_iam_policy_bindings_v2" "cc-policy-bindings" {
  group = dynatrace_iam_group.cc-iam-group.id
  account = var.accountUUID
  dynamic "policy" {
    for_each = keys(var.groups_and_permissions[local.group_name].attached_policies)
    content {
      id = element([for item in var.group_policies : item if item["name"] == policy.value], 0).id
      parameters = var.groups_and_permissions[local.group_name].attached_policies[policy.value].policy_parameters
      metadata = var.groups_and_permissions[local.group_name].attached_policies[policy.value].policy_metadata
    }
  }
}

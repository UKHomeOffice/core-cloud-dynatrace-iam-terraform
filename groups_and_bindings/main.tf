resource "dynatrace_iam_group" "cc-iam-group" {
  name                       = var.group_name
  federated_attribute_values = var.federated_attribute_values
}

resource "dynatrace_iam_policy_bindings_v2" "cc-policy-bindings" {
  group    = dynatrace_iam_group.cc-iam-group.id
  for_each = var.attached_policies

  environment = each.value.environment

  policy {
    id         = element([for item in var.iam_policies : item if item["name"] == each.key], 0).id
    parameters = each.value.policy_parameters
    metadata   = each.value.policy_metadata
  }
}

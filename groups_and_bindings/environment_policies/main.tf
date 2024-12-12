resource "dynatrace_iam_policy_bindings_v2" "cc-env-policy-bindings" {
  group = var.group_id
  environment = var.env_id
  policy{
    id = var.policy_id
    parameters = var.policy_parameters
    metadata = var.policy_metadata
  }
}

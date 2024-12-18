variable "all_policies" {
  type        = any
  description = "Combination of list of predefined and custom policies."
}

variable "group_name" {
  description = "The name of the group used as an id"
  type        = string
}

variable "attached_policies" {
  description = "A map with the key being the policy name and the value object containing the policy binding configuration"
  type = map(object({
    policy_parameters = optional(map(string), null)
    policy_metadata   = optional(map(string), null)
    environment       = string
  }))
}

variable "federated_attribute_values" {
  description = "A list of federated attribute values"
  type        = list(string)
}

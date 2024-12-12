variable "group_id" {
  type = string
}
variable "env_id" {
  type = string
}
variable "policy_id" {
  type = string
}
variable "policy_parameters" {
  type = map(string)
  default = null
}
variable "policy_metadata" {
  type = map(string)
  default = null
}


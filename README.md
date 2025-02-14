# What does the repository do?

This repository creates the following resources:

1. Dynatrace IAM groups
2. Dynatrace IAM policies
3. Bindings of the policies - both predefined and custom - to the created/configured groups.

# What is not implemented?

1. As required in the ticket, boundaries will not be created by the repository as the functionality is not available through code.
2. Policies are not created with environment scope as it is a deprecated functionality (as per the [terraform documentation](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy)). However, the functionality could be achieved through policy bindings.

# Inputs

Please refer to the [variables.tf](variables.tf) and [iam\_group\_variable\_type.tf](iam\_group\_variable\_type.tf) for details on the input variables.

# Outputs

No outputs
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_dynatrace"></a> [dynatrace](#requirement\_dynatrace) | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_dynatrace"></a> [dynatrace](#provider\_dynatrace) | ~> 1.0 |

## Resources

| Name | Type |
|------|------|
| [dynatrace_iam_policy.env_policy](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_accountUUID"></a> [accountUUID](#input\_accountUUID) | Root account UUID | `string` | n/a | yes |
| <a name="input_groups_and_permissions"></a> [groups\_and\_permissions](#input\_groups\_and\_permissions) | Map containing group name, federated values and policy attachment configuration | <pre>map(object({<br/>    # Refer to :<br/>    #   https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_group#federated_attribute_values-1<br/>    # and<br/>    #   https://docs.dynatrace.com/docs/manage/identity-access-management/user-and-group-management/access-group-management<br/>    # for more details<br/>    federated_attribute_values = optional(list(string))<br/>    # Refer to https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy_bindings_v2 and<br/>    # https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy<br/>    # for more details.<br/>    # Please note that 'environment' is deprecated from the 'iam_policy'<br/>    # resource and therefore not supported here - only 'account' is supported<br/>    # For documentation on parameters refer to:<br/>    #   https://docs.dynatrace.com/docs/manage/identity-access-management/permission-management/manage-user-permissions-policies/advanced/iam-policy-templating<br/>    attached_policies = optional(map(object({<br/>      policy_parameters = optional(map(string), null)<br/>      policy_metadata   = optional(map(string), null)<br/>      environment       = string<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_iam_policies"></a> [iam\_policies](#input\_iam\_policies) | Map of policy names and their policy query statement. | `map(string)` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
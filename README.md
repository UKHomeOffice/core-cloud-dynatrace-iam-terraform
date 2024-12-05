# What does the repository do?

This repository originated from the issue [CCL-1274](https://collaboration.homeoffice.gov.uk/jira/browse/CCL-1274) and creates the following resources:

1. Dynatrace IAM groups
2. Dynatrace IAM policies
3. Bindings of the policies - both predefined and custom - to the created/configured groups.

# What is not implemented?

1. As required in the ticket, boundaries will not be created by the repository as the functionality is not available through code.
2. Policies are not created with environment scope as it is a deprecated functionality (as per the [terraform documentation](https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs/resources/iam_policy)). However, the functionality could be achieved through policy statement condition.

# Inputs

Please refer to the [variables.tf](variables.tf) and [iam\_group\_variable\_type.tf](iam\_group\_variable\_type.tf) for details on the input variables.

# Outputs

No outputs
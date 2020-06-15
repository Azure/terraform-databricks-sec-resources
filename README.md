## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| databricks | n/a |
| null | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_default\_packages | List of uris for any custom Python packages (.whl) to install on clusters by default. | `list(string)` | `[]` | no |
| databricks\_api\_token | A PAT or other valid token to authorise interaction with the Databricks host. | `string` | n/a | yes |
| databricks\_host | URL to the Databricks workspace to interact with. | `string` | n/a | yes |
| whl\_upload\_script\_path | Path to a bash script which downloads the whls in cluster\_default\_packages, and uploads them to dbfs. | `string` | `"./scripts/whls_to_dbfs.sh"` | no |

## Outputs

No output.

# Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
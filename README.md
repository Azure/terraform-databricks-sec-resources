## Requirements

An install of the latest release of the [Databricks Labs Terraform provider](https://github.com/databrickslabs/terraform-provider-databricks) is required, which cannot yet be done through `tf init` or targeting the latest version in config.

Run: 
```shell
$ curl https://raw.githubusercontent.com/databrickslabs/databricks-terraform/master/godownloader-databricks-provider.sh | bash -s -- -b $HOME/.terraform.d/plugins
```

## Providers

| Name | Version |
|------|---------|
| databricks | n/a |
| null | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_default\_packages | List of uris for any custom Python packages (.whl) to install on clusters by default. | `list(string)` | `[]` | no |
| clusters\_depend\_on | n/a | `any` | `null` | no |
| databricks\_workspace | Databricks workspace to deploy resources to. | `any` | n/a | yes |
| service\_principal\_client\_id | Service Principal or App Registration Client ID for workspace auth. | `string` | n/a | yes |
| service\_principal\_client\_secret | Service Principal or App Registration Client secret for workspace auth. | `string` | n/a | yes |
| subscription\_id | ID of the Azure subscription in which the Databricks workspace is located. | `string` | n/a | yes |
| tenant\_id | ID of the Azure tenant in which the Databricks workspace is located. | `string` | n/a | yes |
| whl\_upload\_script\_path | Path to a bash script which downloads the whls in cluster\_default\_packages, and uploads them to dbfs. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| high\_concurrency\_cluster | n/a |
| standard\_cluster | n/a |

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
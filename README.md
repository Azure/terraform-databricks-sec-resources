# This is an ALPHA stage module

This module is not suitable for production.

There is no guarantee.

This module is only a demo code.


## Requirements

- Install the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) and log in with `$ az login`
- Install pip with `$ sudo apt get install python-pip`, and use it to install the [Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html#install-the-cli). Note that this may require you to [update your path](https://stackoverflow.com/questions/52012006/databricks-cli-not-installing-on-ubuntu-18-04) following the pip install, so test the install with `$ databricks -h`.
- Install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)
- Install zip with `$ sudo apt install zip` on Linux
- Install version 0.2.0 of the [Databricks Labs Terraform provider](https://github.com/databrickslabs/terraform-provider-databricks). This specific version is required due to a [known bug](https://github.com/databrickslabs/terraform-provider-databricks/issues/127) introduced in later versions which affects service principal authentication, or [`azure_auth`](https://databrickslabs.github.io/terraform-provider-databricks/provider/#azure-service-principal-auth). This can be installed as follows:

```shell
wget https://github.com/databrickslabs/terraform-provider-databricks/releases/download/v0.2.0/databricks-terraform_0.2.0_Linux_64-bit.tar.gz \
-P $HOME/.terraform.d/plugins && \
tar xvfz $HOME/.terraform.d/plugins/databricks-terraform_*.tar.gz \
-C $HOME/.terraform.d/plugins && \
rm $HOME/.terraform.d/plugins/LICENSE \
$HOME/.terraform.d/plugins/NOTICE \
$HOME/.terraform.d/plugins/databricks-terraform_*.tar.gz
```

The `examples` directory contains ready to run usage examples for the module.

Before running, in order for the Databricks provider to complete authentication, you must set several environment variables on your machine as follows:

```shell
# ID of the Azure subscription in which the Databricks workspace is located
export ARM_SUBSCRIPTION_ID="your-sub-id"

# ID of the Azure tenant in which the Databricks workspace is located
export ARM_TENANT_ID="your-tenant-id"

# Service Principal or App Registration Client ID for workspace auth
export ARM_CLIENT_ID="your-client-id"

# Service Principal or App Registration Client secret for workspace auth
export ARM_CLIENT_SECRET="your-client-secret"
```

The module also provides the option to deploy a pre-created local [Jupyter notebook](https://jupyter.org/) to the workspace. This can contain any valid Jupyter notebook content. Use of variable `notebook_path` triggers this resource deployment, but as in the minimal example it can be foregone entirely, deploying just the workspace and clusters. For ease of getting started, an example notebook is provided at `./notebooks/notebook.ipynb`, and the complete example uploads this by default.

If a notebook is deployed, two APIM APIs are automatically deployed, which together use the [Databricks Jobs](https://docs.databricks.com/jobs.html) API to invoke the notebook via an HTTP POST.

- The first API `create_job_api` sets up a notebook task job in your Databricks instance.
- The second API `invoke_notebook_api` runs this job given its ID (1 by default).

Both APIs can be fired with optional custom parameters immediately after deployment using the "Test" window of APIM in the Azure Portal.

## Providers

| Name | Version |
|------|---------|
| databricks | n/a |
| null | n/a |
| time | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_default\_packages | List of uris for any custom Python packages (.whl) to install on clusters by default. | `list(string)` | `[]` | no |
| databricks\_workspace | Databricks workspace to deploy resources to. | `any` | n/a | yes |
| apim | API Management resource object to deploy notebook invocation API(s) to. | `any` | n/a | yes |
| prefix | A naming prefix to be used in the creation of unique names for deployed Databricks resources. | `list(string)` | `[]` | no |
| suffix | A naming suffix to be used in the creation of unique names for deployed Databricks resources. | `list(string)` | `[]` | no |
| whl\_upload\_script\_path | Path to a bash script which downloads the whls in cluster\_default\_packages, and uploads them to dbfs. | `string` | `""` | no |
| notebook\_path | Optional relative path to a local Jupyter notebook to deploy to the workspace. | `string` | "" | no |
| notebook\_name | If deploying, the desired name of the deployed notebook as it will appear in the workspace. | `string` | `"mynotebook"` | no |

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
